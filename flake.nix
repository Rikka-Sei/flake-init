{
  description = "flake-init: a bash project template with flake-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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
          version = "0.1.1";

          src = ./src;

          buildInputs = with pkgs; [
            newt
            makeWrapper # **关键：添加 makeWrapper 到 buildInputs**
          ];

          installPhase = ''
            ls
            
            mkdir -p $out/bin
            cp -r ./ $out/bin

            chmod +x $out/bin/flake-init.sh
            wrapProgram $out/bin/flake-init.sh --prefix PATH : ${pkgs.newt}/bin
          '';
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/flake-init.sh";
          };

          flake-init = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/flake-init.sh";
          };
        };
      }
    );
}