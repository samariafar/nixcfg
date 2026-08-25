final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    claudebar = prev.stdenv.mkDerivation rec {
      pname = "gnome-shell-extension-claudebar";
      # ATTENTION: downgraded from 1.2.5. Upstream deleted the v1.2.5 release
      # AND its git tag — the asset 404s and the tags API lists only v1.1.0 and
      # v1.0.0, so 1.2.5 is no longer fetchable from anywhere. This was already
      # unbuildable on 25.11; it only stayed hidden because the built output
      # was cached in the store while its source had been garbage-collected.
      # Bump back up if upstream republishes a newer release.
      version = "1.1.0";

      src = prev.fetchzip {
        url = "https://github.com/bilbilak/claudebar/releases/download/v${version}/claudebar-linux-gnome-v${version}.zip";
        hash = "sha256-B9m30s1NqhHA9YSBZ+rTbuejT2a1UY/oKuk1QijtYcM=";
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
