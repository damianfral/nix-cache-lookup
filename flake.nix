{
  description = "Check whether a Nix flake output already exists in configured binary caches.
";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      precommitCheck = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          actionlint.enable = true;
          alejandra.enable = true;
          shellcheck.enable = true;
        };
      };
    in {
      checks = {pre-commit-check = precommitCheck;};

      devShells.default = pkgs.mkShell {
        shellHook = precommitCheck.shellHook;
      };
    });

  nixConfig = {
    extra-substituters = [
      "https://opensource.cachix.org"
    ];
    extra-trusted-public-keys = [
      "opensource.cachix.org-1:6t9YnrHI+t4lUilDKP2sNvmFA9LCKdShfrtwPqj2vKc="
    ];
  };
}
