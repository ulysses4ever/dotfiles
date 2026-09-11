{ lib
, buildNpmPackage
, nodejs
, pkg-config
, python3
, cairo
, pango
, libjpeg
, giflib
, librsvg
, pixman
, makeWrapper
}:

buildNpmPackage {
  pname = "pyret";
  version = "0.1.24";

  src = ./.;

  npmDepsHash = "sha256-52zTMawZNEYVLDWwald9Zdufn7kO/Txh3KKsgY/R7hI=";

  # pyret-npm ships prebuilt .jarr files; the only thing to compile is the
  # `canvas` native addon, which npmRebuild handles.
  dontNpmBuild = true;

  nativeBuildInputs = [ pkg-config python3 makeWrapper ];
  buildInputs = [ cairo pango libjpeg giflib librsvg pixman ];

  # client-lib.js computes `nodeModulesPath` as `__dirname/node_modules` and
  # symlinks it into `<cwd>/.pyret/node_modules`, which is what node's walk-up
  # from the compiled output later resolves against. npm hoists deps flat, so
  # that path does not exist and the symlink lands dangling -- pyret then only
  # works in a tree that happens to have node_modules above it. Pointing the
  # nested path back at the flat one makes the symlink valid from any cwd.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pyret
    cp -r node_modules $out/lib/pyret/node_modules
    ln -s $out/lib/pyret/node_modules \
      $out/lib/pyret/node_modules/pyret-npm/node_modules

    makeWrapper ${nodejs}/bin/node $out/bin/pyret \
      --add-flags $out/lib/pyret/node_modules/pyret-npm/pyret.js \
      --prefix NODE_PATH : $out/lib/pyret/node_modules

    runHook postInstall
  '';

  meta = with lib; {
    description = "The Pyret programming language CLI";
    homepage = "https://pyret.org";
    license = licenses.mit;
    mainProgram = "pyret";
    platforms = platforms.linux;
  };
}
