# ATTENTION: temporary backport of nixpkgs 2d02af8e2d ("herdr-desktop: fix
# build with system libs"). herdr-desktop 0.1.10 in nixos-unstable fails to
# build because zstd-sys can't find libzstd via pkg-config. Drop this overlay
# once nixos-unstable ships herdr-desktop >= 0.1.13.
final: prev: {
  unstable = prev.unstable // {
    herdr-desktop = prev.unstable.herdr-desktop.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ prev.unstable.zstd ];
    });
  };
}
