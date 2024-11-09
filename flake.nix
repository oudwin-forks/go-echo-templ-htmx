{
  description = "A Nix-flake-based Go 1.22 development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    templ.url = "github:a-h/templ";
  };

  outputs = { self, nixpkgs, templ }@inputs:
    let
      goVersion = 23; # Change this to update the whole stack
      overlays = [ (final: prev: { go = prev."go_1_${toString goVersion}"; }) ];

      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
        inherit system;
      });
      templ = system: inputs.templ.packages.${system}.templ;
    in
    {
      packages = forEachSupportedSystem ({ pkgs, system }: {
      korokidsweb = pkgs.buildGoModule {
        pname = "korokidsweb";
        version = "0.0.1";
        src = ./.; 
        vendorHash = null;
  
        preBuild = ''
          ${templ system}/bin/templ generate
        '';
      };
    });
      devShells = forEachSupportedSystem ({ pkgs, system }: {
        default = pkgs.mkShell {
          # added to shell path. Avaiable during dev
          packages = with pkgs; [
            # goimports, godoc, etc.
            gotools

            # https://github.com/golangci/golangci-lint
            golangci-lint
          ];
          # dependencies required to build project. Also available during dev
          buildInputs = with pkgs; [
            # go (version is specified by overlay)
            go
            (templ system)
          ];
        };
      });
    };
}
