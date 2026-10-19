# HARBINGER

A microvm for agentic workflows. 

```
nix run /home/jerome/dev/harbinger/harbinger-vm                                     
```

## VM Configuration
QEMU
+ 500 MB RAM
+ 1 vCPU
+ auto-login as root
+ automatically uses hosts' `/nix/store` (read-only)
+ `/workspace` mapped to `/home/jerome/harbinger-workspace`
+ `pi` installed from the `pi-fowler` flake input
  (`git+http://git.nemesis.home.arpa/jerome/pi-fowler`)
