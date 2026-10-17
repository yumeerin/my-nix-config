{ ... }: {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  users.users.yume.extraGroups = [ "docker" ];
}
