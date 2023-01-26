{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.hardware.nvidia-offload;

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
in {
  options.modules.nixos.hardware.nvidia-offload = {
    enable = mkEnableOption "Enable the NVIDIA optimus prime offload mode";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        nvidia-offload
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools
      ];

      variables = {
        LIBVA_DRIVER_NAME = "nvidia";
        VDPAU_DRIVER = "nvidia";
        GBM_BACKEND = "nvidia-drm";
      };
    };

    services.xserver.videoDrivers = ["nvidia"];

    hardware = {
      nvidia = {
        modesetting.enable = true;
        powerManagement = {
          enable = true;
          finegrained = true;
        };

        prime = {
          offload.enable = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };

      opengl.extraPackages = with pkgs; [nvidia-vaapi-driver];
    };
  };
}