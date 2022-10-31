{
  description = "Kubernetes infra";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils/master";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [devshell.overlay];
      };
      gpg = "${pkgs.gnupg}/bin/gpg";
    in {
      devShell = pkgs.devshell.mkShell {
        name = "k8s-devshell";
        imports = [(pkgs.devshell.extraModulesDir + "/git/hooks.nix")];
        devshell.motd = "";
        devshell.startup.load_gpg_keys = pkgs.lib.noDepEntry ''
          _sopsAddKey() {
            ${gpg} --quiet --import "$key"
            local fpr
            # only add the first fingerprint, this way we ignore subkeys
            fpr=$(${gpg} --with-fingerprint --with-colons --show-key "$key" \
                  | awk -F: '$1 == "fpr" { print $10; exit }')
          }

          sopsImportKeysHook() {
            local dir
            for dir in "${toString ./.}/secrets/keys"; do
              while IFS= read -r -d ''' key; do
                _sopsAddKey "$key"
              done < <(find -L "$dir" -type f \( -name '*.gpg' -o -name '*.asc' \) -print0)
            done
          }

          sopsImportKeysHook
        '';
        commands = [
          {
            name = "apply-secrets";
            category = "secrets";
            command = "${pkgs.bash}/bin/bash ${toString ./secrets/apply.sh}";
          }
        ];
        # https://github.com/numtide/devshell/blob/master/modules/env.nix#L57
        env = [
          {
            name = "SECRETS_CONTEXT";
            value = "depsos";
          }
        ];
        packages = [pkgs.kubectl pkgs.sops pkgs.k9s];
      };
    });
}
