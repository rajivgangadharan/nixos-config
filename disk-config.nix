# Disko disk layout
# Partitions /dev/nvme0n1 (NVMe SSD — root) and /dev/sda (HDD — data).
# Used during install: disko --mode zap_create_mount ./disk-config.nix
# The disko NixOS module (imported in configuration.nix) then generates
# the fileSystems / swapDevices entries from this file automatically.
{
  disko.devices = {

    # ── NVMe SSD — root drive ───────────────────────────────────────────────────
    disk.nvme0 = {
      type   = "disk";
      device = "/dev/disk/by-id/nvme-CT500P3SSD8_2234E65A6AD2";
      content = {
        type = "gpt";
        partitions = {

          # EFI System Partition — systemd-boot lives here
          esp = {
            type = "EF00";
            size = "512M";
            content = {
              type       = "filesystem";
              format     = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          # Swap
          swap = {
            type = "8200"; # Linux swap GPT type
            size = "8G";
            content.type = "swap";
          };

          # Btrfs root — subvolumes for clean snapshot/rollback boundaries
          btrfs_root = {
            size = "100%";
            content = {
              type      = "btrfs";
              extraArgs = [ "-f" "-L" "nixos" ]; # force-format, label

              subvolumes = {
                # System root — snapshot this to roll back NixOS generations
                "@" = {
                  mountpoint   = "/";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };

                # Optional software
                "@opt" = {
                  mountpoint   = "/opt";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };

                # Snapshots mount point (used by snapper / btrbk)
                "@snapshots" = {
                  mountpoint   = "/.snapshots";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };
              };
            };
          };
        };
      };
    };

    # ── SATA SSD — data drive (Crucial MX500) ───────────────────────────────────
    disk.hdd = {
      type   = "disk";
      device = "/dev/disk/by-id/ata-CT500MX500SSD1_2013E297EA30";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type      = "btrfs";
              extraArgs = [ "-f" "-L" "data" ];

              subvolumes = {
                # Nix store — large, read-heavy
                "@nix" = {
                  mountpoint   = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };

                # User home — snapshotted independently of root
                "@home" = {
                  mountpoint   = "/home";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };

                # Variable data — @log mounts on top for finer granularity
                "@var" = {
                  mountpoint   = "/var";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };

                # System logs — persists across root rollbacks
                "@log" = {
                  mountpoint   = "/var/log";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };

                # Temporary files — no compression (transient data)
                "@tmp" = {
                  mountpoint   = "/tmp";
                  mountOptions = [ "noatime" "ssd" "discard=async" ];
                };

                "@data" = {
                  mountpoint   = "/data";
                  mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
                };
              };
            };
          };
        };
      };
    };

  };
}
