{ pkgs, lib, config, inputs, ... }:

{
  packages = [ pkgs.git ];
  languages.zig.enable = true;
}
