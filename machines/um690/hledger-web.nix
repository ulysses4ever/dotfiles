# hledger-web from our fork (~/Dev/hledger, branch web-mobile): upstream's
# main line (1.99) plus the phone layout the family will not do without.
# hledger-lib and hledger are built from the same source. Each package
# directory is copied under its own name, as the test recipe
# ~/Dev/accounting/hosting/hledger-from-source.nix does, so the builds are
# shared with it: what was tested is what is deployed, without a rebuild.
# The git tree lacks the command docs the CLI embeds; they are stubbed,
# which only matters to `hledger help`.
#
# src is a checkout (a path) or the flake input hledger-src; finance.nix
# builds the latter as the fallback the services start from until
# hledger-deploy has run (see there).
{ pkgs, src }:
let
  hlib = pkgs.haskell.lib;
  relax = p: hlib.dontCheck (hlib.doJailbreak p);
  dir = name: builtins.path { path = "${src}/${name}"; inherit name; };
  stubDocs = p: hlib.overrideCabal p (o: {
    postPatch = (o.postPatch or "") + ''
      for f in $(grep -o 'embeddedfiles/[^"]*' Hledger/Cli/DocFiles.hs | sort -u); do
        mkdir -p "$(dirname "$f")"
        if [ ! -e "$f" ]; then rm -f "$f"; echo "Documentation is not generated in this build." > "$f"; fi
      done
    '';
  });
  hp = pkgs.haskellPackages.extend (self: super: {
    hledger-lib = relax (self.callCabal2nix "hledger-lib" (dir "hledger-lib") { });
    hledger = stubDocs (relax (self.callCabal2nix "hledger" (dir "hledger") { }));
    hledger-web = relax (self.callCabal2nix "hledger-web" (dir "hledger-web") { });
  });
in
hp.hledger-web
