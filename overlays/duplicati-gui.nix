final: prev:

# Upstream Duplicati ships a self-contained GUI/tray AppImage that bundles
# .NET 10 + Avalonia + every backend DLL. Wrapping it via
# `appimageTools.wrapType2` is the path of least resistance — it builds an
# FHS env with the host libs the AppImage expects (libicu for .NET
# globalization, libnotify for desktop notifications) and exposes a single
# `duplicati-gui` entrypoint.
#
# AppRun behaviour: invoked with no matching `$0`/`$1` it falls through to
# `exec usr/bin/duplicati`, which is the tray binary. Calling the wrapper
# `duplicati-gui` (no AppRun case match) gives us the tray by default.
#
# Update flow: bump `version` + `build` (the dated suffix in the upstream
# URL) and refresh `hash` via `nix-prefetch-url <url>` then
# `nix hash convert --to sri sha256:<hash>`.

let
  pname = "duplicati-gui";
  version = "2.3.0.1";
  build = "2026-04-24";

  src = prev.fetchurl {
    url = "https://updates.duplicati.com/stable/duplicati-${version}_stable_${build}-linux-x64-gui.appimage";
    hash = "sha256-UyZCeAMc9nMTPIoz88AlHZ8dIQU31zZ9uUrbu1XpEpw=";
  };

  appimageContents = prev.appimageTools.extract {
    inherit pname version src;
  };
in
{
  duplicati-gui = prev.appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: with pkgs; [
      icu       # .NET globalization (CultureInfo, ICU regex)
      libnotify # desktop notifications from the tray
    ];

    extraInstallCommands = ''
    	install -m 444 -D ${appimageContents}/com.duplicati.app.desktop $out/share/applications/com.duplicati.app.desktop
    	install -m 444 -D ${appimageContents}/duplicati.png $out/share/pixmaps/duplicati.png

    	substituteInPlace $out/share/applications/com.duplicati.app.desktop --replace-fail 'Exec=duplicati' "Exec=$out/bin/${pname}"
    '';

    meta = with prev.lib; {
      description = "Duplicati GUI / system-tray icon (AppImage bundle)";
      homepage = "https://duplicati.com/";
      license = licenses.lgpl21Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = pname;
    };
  };
}
