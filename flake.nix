{
  description = "Simple single-file LÖVE2D game with dev shell (lurker hot-reload) and web build for itch.io";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    love-js = {
      url = "github:TannerRogalsky/love.js";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, love-js }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Build a .love file from the current project directory (editable files)
        loveFile = pkgs.stdenv.mkDerivation {
          name = "mygame.love";
          src = ./.;
          buildPhase = ''
            ${pkgs.zip}/bin/zip -9 mygame.love main.lua
          '';
          installPhase = ''
            mkdir -p $out
            cp mygame.love $out/
          '';
        };

      in {
        packages = {
          default = self.packages.${system}.native;

          native = loveFile;

          web = pkgs.stdenv.mkDerivation {
            name = "mygame-web";
            src = loveFile;
            nativeBuildInputs = [ pkgs.emscripten pkgs.python3 ];
            buildPhase = ''
              mkdir -p release
              cp $src/mygame.love release/game.love
              cp -r ${love-js}/release/* release/

              cd release
              python emscripten/tools/file_packager.py game.data --preload game.love@/ --js-output=game.js
              sed -i 's|{{{ LOVE_GAME }}}|game.js|g' index.html
            '';
            installPhase = ''
              mkdir -p $out
              cp -r release/* $out/
            '';
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.love_11 ];

          shellHook = ''
            echo "Run game:"
            echo "  love ."
          '';
        };
      });
}