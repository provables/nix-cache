{
  description = "A Nix cache service";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    shell-utils.url = "github:waltermoreira/shell-utils";
    attic.url = "github:zhaofengli/attic";
  };

  outputs =
    { self, ... }@inputs:
      with inputs.flake-utils.lib; eachSystem [
        system.aarch64-darwin
        system.aarch64-linux
        system.x86_64-darwin
        system.x86_64-linux
      ]
        (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          shell = inputs.shell-utils.myShell.${system};
          attic = inputs.attic.packages.${system}.attic;
          atticConfig = pkgs.stdenv.mkDerivation {
            name = "attic-config";
            src = ./.;
            dontFixup = true;
            buildInputs = with pkgs; [
              jinja2-cli
            ];
            buildPhase = ''
              mkdir -p $out
              jinja2 --format=yaml server.toml.j2 config.yaml > $out/server.toml
            '';
          };
          configuredAttic = pkgs.stdenv.mkDerivation {
            name = "configured-attic";
            src = ./.;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            buildInputs = [ attic ];
            buildPhase = ''
              mkdir -p $out/bin
              ln -s ${attic}/bin/attic $out/bin
              makeWrapper ${attic}/bin/atticd $out/bin/atticd \
                --add-flags "-f ${atticConfig}/server.toml"
              makeWrapper ${attic}/bin/atticadm $out/bin/atticadm \
                --add-flags "-f ${atticConfig}/server.toml"
            '';
          };
          dev = shell {
            name = "cache";
            packages = with pkgs; [
              configuredAttic
              jinja2-cli
            ];
          };
        in
        {
          packages = {
            default = configuredAttic;
          };
          devShells = {
            default = dev;
          };
        });
}
