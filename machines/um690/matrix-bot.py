#!/usr/bin/env python3
import hashlib
import hmac
import http.server
import json
import os
import sys
import time
import urllib.parse
import urllib.request

MATRIX_HOMESERVER = os.environ.get("MATRIX_HOMESERVER", "https://matrix.org")
MATRIX_TOKEN = os.environ["MATRIX_TOKEN"]
MATRIX_ROOM_ID = os.environ.get("MATRIX_ROOM_ID", "!YWYQDCuIpuQHzGrLzd:matrix.org")
WEBHOOK_SECRET = os.environ["WEBHOOK_SECRET"]
PORT = int(os.environ.get("PORT", "8765"))
HIGH_PRIORITY_LABEL = os.environ.get("HIGH_PRIORITY_LABEL", "priority: high \U0001f525")


def verify_signature(body: bytes, signature: str) -> bool:
    mac = hmac.new(WEBHOOK_SECRET.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest("sha256=" + mac, signature)


def send_matrix_message(plain: str, html: str) -> None:
    txn_id = str(int(time.time() * 1000))
    room = urllib.parse.quote(MATRIX_ROOM_ID, safe="")
    url = (
        f"{MATRIX_HOMESERVER}/_matrix/client/v3/rooms"
        f"/{room}/send/m.room.message/{txn_id}"
    )
    payload = {
        "msgtype": "m.text",
        "body": plain,
        "format": "org.matrix.custom.html",
        "formatted_body": html,
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, method="PUT")
    req.add_header("Authorization", f"Bearer {MATRIX_TOKEN}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as resp:
        resp.read()


class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/webhook":
            self.send_response(404)
            self.end_headers()
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        sig = self.headers.get("X-Hub-Signature-256", "")
        if not verify_signature(body, sig):
            self.send_response(401)
            self.end_headers()
            return

        event = self.headers.get("X-GitHub-Event", "")
        if event not in ("issues", "pull_request"):
            self.send_response(204)
            self.end_headers()
            return

        payload = json.loads(body)
        if payload.get("action") != "labeled":
            self.send_response(204)
            self.end_headers()
            return

        label = payload.get("label", {}).get("name", "")
        if label != HIGH_PRIORITY_LABEL:
            self.send_response(204)
            self.end_headers()
            return

        actor = payload.get("sender", {}).get("login", "unknown")
        item = payload.get("issue") or payload.get("pull_request") or {}
        title = item.get("title", "")
        html_url = item.get("html_url", "")
        kind = "issue" if "issue" in payload else "PR"

        plain = f"@{actor} marked as a high priority {kind}:\n* {title} {html_url}"
        html = (
            f"@{actor} marked as a high priority {kind}:<br>"
            f'<ul><li><a href="{html_url}">{title}</a></li></ul>'
        )
        try:
            send_matrix_message(plain, html)
        except Exception as e:
            print(f"Failed to send Matrix message: {e}", file=sys.stderr, flush=True)
            self.send_response(500)
            self.end_headers()
            return

        self.send_response(200)
        self.end_headers()

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)


if __name__ == "__main__":
    server = http.server.HTTPServer(("127.0.0.1", PORT), WebhookHandler)
    print(f"Listening on 127.0.0.1:{PORT}", flush=True)
    server.serve_forever()
