{
  description = "flake-init: a bash project template with flake-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            newt
          ];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "flake-init";
          version = "0.1.0";

          buildInputs = with pkgs; [
            newt
          ];

          src = ./src;

          installPhase = ''
            mkdir -p $out/bin
            cp flake-init.sh $out/bin/flake-init
            chmod +x $out/bin/flake-init
          '';
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/flake-init";
          };

          flake-init = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/flake-init";
          };
        };
      }
    );
}
