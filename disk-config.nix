# /tmp/disk-config.nix

{
  disko.devices = {
    disk.nvme0 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/mnt/boot";
              createOptions = [ "-F" "32" ];
            };
          };
          swap = {
            type = "swap";
            size = "8G";
            content = {
              type = "swap";
            };
          };
          btrfs_root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/mnt";
            };
          };
        };
      };
    };

    disk.hdd = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/mnt/data";
            };
          };
        };
      };
    };
  };
}

