# Helium Browser (imputnet/helium): Chromium-based browser, not packaged in
# nixpkgs. This wraps the official x86_64 AppImage as a Nix package.
{ pkgs, ... }:

let
  pname = "helium";
  version = "0.17.1.1";
  src = pkgs.fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    sha256 = "13vq1vsswm31lr5i6256hkajzpqywjg9k7dbyymrfn2byc63wh0k";
  };
  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  # wrapType2 only installs bin/helium; also ship the .desktop entry and
  # icons so Helium shows up in KDE's application launcher.
  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/helium.desktop -t $out/share/applications
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';
}