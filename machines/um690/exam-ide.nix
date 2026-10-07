# exam-ide.nix — the in-browser exam IDE at https://exam.cu-cs-classes.site/,
# for 230's programming exams under LockDown Browser (2026-10-06).
#
# Since 2026-10-07 the record points at artemserver's own tunnel, where the
# seats run (~/exam/exam-ide there, ~/edu/exam-ide/README.md here). This
# ingress is the fallback: ~/edu/exam-ide/exam-dns.py points the record back
# at this tunnel, 2b80d7a7, after up.sh on this machine.
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
# One hostname. Its DNS record is the tunnel's CNAME in the account that holds
# cu-cs-classes.site, made the way the grader's was: `exam` ->
# 2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19.cfargotunnel.com, proxied. The
# certificate in ~/.cloudflared is logged in for pelenitsyn.site only, so
# `cloudflared tunnel route dns` cannot make it from here.
{ config, lib, pkgs, ... }:

{
  services.cloudflared.tunnels."2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19".ingress."exam.cu-cs-classes.site" = {
    service = "http://localhost:8090";
  };
}
