{ mango, ... }:
{
  imports = [
    mango.nixosModules.mango
  ];

  programs.mango.enable = true;

}

