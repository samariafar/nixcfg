{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ffmpeg-full # Comprehensive video/audio tools and codecs
    libheif # HEIC/HEIF image format
    libraw # RAW photo format

    # GStreamer plugins for video format support in GNOME apps
    gst_all_1.gst-libav # libav-based codecs (covers most formats)
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-vaapi # Hardware-accelerated decoding
  ];
}
