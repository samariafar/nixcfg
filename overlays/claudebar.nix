final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    claudebar = prev.stdenv.mkDerivation rec {
      pname = "gnome-shell-extension-claudebar";
      version = "1.2.5";

      src = prev.fetchzip {
        url = "https://github.com/bilbilak/claudebar/releases/download/v${version}/claudebar-linux-gnome-v${version}.zip";
        hash = "sha256-xUnBTUDI1xcmc8G+S06pQi0AFDlcGcC8LqrS7bT6T2M=";
        stripRoot = false;
      };

      installPhase = ''
      	runHook preInstall
      	mkdir -p $out/share/gnome-shell/extensions/claudebar@bilbilak.org
      	cp -r $src/* $out/share/gnome-shell/extensions/claudebar@bilbilak.org/

      	runHook postInstall
      '';

      passthru.extensionUuid = "claudebar@bilbilak.org";
      passthru.extensionPortalSlug = "claudebar";

      meta = with prev.lib; {
        description = "Shows Claude.ai subscription session and weekly usage in the top bar";
        homepage = "https://github.com/bilbilak/claudebar";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    };
  };
}
