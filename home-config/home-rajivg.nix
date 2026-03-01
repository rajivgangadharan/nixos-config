# =============================================================================
# Home Manager — Rajiv G (rajivg)
#
# Inherits the shared Regolith-style i3 desktop from home.nix and sets
# this user's identity fields.
# =============================================================================
{ config, pkgs, lib, ... }:

{
  imports = [ ./home.nix ];

  home.username      = "rajivg";
  home.homeDirectory = "/home/rajivg";
}
