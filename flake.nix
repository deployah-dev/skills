{
  description = "Deployah Agent Skills and Plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Revisions are authoritative in flake.lock (do not pin SHAs in these URLs).
    deployah-src = {
      url = "github:deployah-dev/deployah";
      flake = false;
    };
    agentskills-src = {
      url = "github:agentskills/agentskills";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      deployah-src,
      agentskills-src,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        packages = import ./nix/packages.nix {
          inherit pkgs agentskills-src;
        };

        validateWiring = import ./nix/validate.nix {
          inherit pkgs deployah-src;
          src = self;
          skills-ref = packages.skills-ref;
        };

        release = import ./nix/release.nix {
          inherit pkgs;
          src = self;
        };
      in
      {
        formatter = pkgs.nixfmt-tree;

        packages = {
          default = packages.skills-ref;
          skills-ref = packages.skills-ref;
          validate = validateWiring.validate;
          inherit release;
        };

        checks = {
          validate = validateWiring.check;
        };

        apps.validate = flake-utils.lib.mkApp {
          drv = validateWiring.validate;
        };

        devShells.default = import ./nix/devshell.nix {
          inherit pkgs;
          skills-ref = packages.skills-ref;
          validate = validateWiring.validate;
        };
      }
    );
}
