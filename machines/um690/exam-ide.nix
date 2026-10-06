# exam-ide.nix — the in-browser exam IDE at https://exam.pelenitsyn.site/,
# for 230's programming exams under LockDown Browser (2026-10-06).
#
# Nothing runs from here but the hostname: the seats are Docker containers
# started by hand from ~/edu/exam-ide/up.sh, one code-server per student on
# the lab's JDK, on an internal network with no way out, behind one Caddy
# proxy on 127.0.0.1:8090. The tunnel publishes that port under one hostname
# because LockDown Browser allows exact hostnames only, so every seat is a
# path, /s1/ to /s9/, each with its own password. No Cloudflare Access on it:
# the students have no identity Access knows, and the seat password is the
# lock. Between exams nothing listens on 8090 and the hostname answers 502.
#
# Two hostnames, one service. exam.pelenitsyn.site was routed with
# `cloudflared tunnel route dns`, since the certificate in ~/.cloudflared is
# logged in for that zone. exam.cu-cs-classes.site, the one students see, is
# the same CNAME made in the account that holds cu-cs-classes.site, as the
# grader's was: `exam` -> 2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19.cfargotunnel.com,
# proxied; or `cloudflared tunnel login` into that zone with TUNNEL_ORIGIN_CERT
# pointing at a second cert file, then `route dns`.
{ config, lib, pkgs, ... }:

let
  service = { service = "http://localhost:8090"; };
in
{
  services.cloudflared.tunnels."2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19".ingress = {
    "exam.cu-cs-classes.site" = service;
    "exam.pelenitsyn.site" = service;
  };
}
