# Lookout (Hack Club) desktop app for NixOS.
#
# Lookout is a Tauri (Rust + WebKitGTK) app; upstream ships .deb/.rpm/pacman
# packages only. This derivation extracts the amd64 .deb and runs it inside a
# buildFHSEnv sandbox that provides the WebKitGTK stack plus every GStreamer
# plugin Lookout needs for screen capture/encoding. Note that the pipewire
# gstreamer plugin (pipewiresrc) ships in the `pipewire` package itself.
{ pkgs }:

let
  pname = "lookout";
  version = "0.3.11";

  src = pkgs.fetchurl {
    url = "https://github.com/hackclub/lookout/releases/download/v${version}/Lookout_linux-${version}_amd64.deb";
    sha256 = "0327d6ec7c3d183e5d7ad2e63f2bd7e2490cccbec744b19d2eb0f76d1a622b31";
  };

  unpacked = pkgs.runCommand "${pname}-${version}-unpacked" {
    nativeBuildInputs = [ pkgs.binutils pkgs.gnutar pkgs.gzip ];
  } ''
    mkdir -p $out
    cd $out
    ar x ${src}
    tar xf data.tar.*
    chmod +x usr/bin/lookout-desktop
  '';

  fhs = pkgs.buildFHSEnv {
    name = "${pname}-${version}";
    targetPkgs = p: with p; [
      webkitgtk_4_1
      gtk3
      gdk-pixbuf
      cairo
      glib
      libsoup_3
      dbus
      openssl
      libgbm
      wayland
      xorg.libxcb
      libx11
      libappindicator-gtk3
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
      pipewire
    ];
    runScript = "${unpacked}/usr/bin/lookout-desktop";
  };
in
pkgs.runCommand "${pname}-${version}-dist" { } ''
  mkdir -p $out/bin $out/share/applications $out/share/icons
  cat > $out/bin/lookout <<EOF
  #!/bin/sh
  # Warn spinning up: buildFHSEnv's bwrap wrapper chdirs to the caller cwd,
  # which may not exist inside the sandbox (e.g. /etc/nixos). Move somewhere safe.
  cd "\''${HOME:-/tmp}" 2>/dev/null || cd /tmp 2>/dev/null || true
  exec ${fhs}/bin/${pname}-${version} "\''$@"
  EOF
  chmod +x $out/bin/lookout
  sed -e 's|^Exec=.*|Exec=lookout %u|' \
    ${unpacked}/usr/share/applications/Lookout.desktop > $out/share/applications/Lookout.desktop
  cp -r ${unpacked}/usr/share/icons/hicolor $out/share/icons/
''