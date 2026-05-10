{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.docker
              pkgs.git
              pkgs.libpq
              pkgs.mysql84
              pkgs.postgresql
              pkgs.python313
              pkgs.uv
              pkgs.sqldef
              pkgs.curl
              pkgs.lsof
              pkgs.coreutils
              pkgs.bash
              (pkgs.writeShellScriptBin "pg_config" ''
                case "''${1:-}" in
                  --libdir)
                    echo "${pkgs.libpq}/lib"
                    ;;
                  --version)
                    echo "PostgreSQL ${pkgs.libpq.version}"
                    ;;
                  *)
                    echo "unsupported pg_config argument: ''${1:-}" >&2
                    exit 1
                    ;;
                esac
              '')
            ];

            shellHook = ''
              export LIBPQ_DIR="${pkgs.libpq}"
            '';
          };
        }
      );
    };
}
