{
  description = "HARBINGER QEMU MicroVM";

  nixConfig = {
    extra-substituters = ["https://microvm.cachix.org"];
    extra-trusted-public-keys = ["microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    microvm,
  }: let
    system = "x86_64-linux";
    workspaceHostPath = "/home/jerome/harbinger-workspace";
  in {
    packages.${system} = {
      default = self.nixosConfigurations.harbinger.config.microvm.declaredRunner;
    };

    nixosConfigurations.harbinger = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        microvm.nixosModules.microvm

        ({
          lib,
          pkgs,
          ...
        }: {
          networking.hostName = "HARBINGER";
          system.stateVersion = "24.11";

          # Root auto-login on serial console
          users.users.root.password = "";
          services.getty.autologinUser = "root";

          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];

          # Packages pre-installed in the VM
          environment.systemPackages = with pkgs; [
            pi-coding-agent
            ripgrep
            tree
          ];

          # SSH access via forwarded port
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };
          networking.firewall.allowedTCPPorts = [22];

          nixpkgs.overlays = [microvm.overlay];

          microvm = {
            hypervisor = "qemu";
            vcpu = 1;
            mem = 500;

            writableStoreOverlay = "/nix/.rw-store";

            volumes = [
              {
                image = "nix-store-overlay.img";
                mountPoint = "/nix/.rw-store";
                size = 4096;
              }
            ];

            # User-mode networking — works out of the box, no tap/bridge needed
            interfaces = [
              {
                type = "user";
                id = "qemu";
                mac = "02:00:00:01:01:01";
              }
            ];

            # Forward host:2222 → guest:22 for SSH
            forwardPorts = [
              {
                host.port = 2222;
                guest.port = 22;
              }
            ];

            # Share the host's /nix/store read-only (avoids building a squashfs image)
            shares = [
              {
                proto = "9p";
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                readOnly = true;
              }
              # Persistent workspace — bi-directional, survives VM restarts
              {
                proto = "9p";
                tag = "workspace";
                source = workspaceHostPath;
                mountPoint = "/workspace";
                readOnly = false;
              }
            ];

            # Auto-create the workspace directory on the host before the VM starts
            preStart = ''
              mkdir -p ${workspaceHostPath}
            '';
          };
        })
      ];
    };
  };
}
