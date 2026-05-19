{ config, pkgs, ... }:

# home-manager's `programs.thunderbird` does NOT mirror Firefox's `policies`
# attribute set — there is no Thunderbird policies.json option here. Privacy /
# UX hardening therefore goes through about:config preferences via
# `profiles.<name>.settings`. If a future home-manager release adds policies
# support, migrate the lock-status entries below to that interface.

{
  programs.thunderbird = {
    enable = true;

    profiles.default = {
      isDefault = true;

      settings = {
        # ------------------------------------------------------------------
        # Telemetry / data reporting — fully off
        # ------------------------------------------------------------------
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "app.shield.optoutstudies.enabled" = false;

        # ------------------------------------------------------------------
        # Privacy headers
        # ------------------------------------------------------------------
        "privacy.donottrackheader.enabled" = true;

        # ------------------------------------------------------------------
        # Default-client / first-run UX
        # ------------------------------------------------------------------
        "mail.shell.checkDefaultClient" = false;
        "mail.provider.suppress_dialog_on_startup" = true;

        # ------------------------------------------------------------------
        # Password manager — disabled (per Firefox parity)
        # ------------------------------------------------------------------
        "signon.rememberSignons" = false;

        # ------------------------------------------------------------------
        # Mail rendering — block remote content (tracking pixels) and prefer
        # simple HTML over original HTML. Toggle the View menu in-message
        # when you actually want full HTML.
        # 0 = original HTML, 1 = simple HTML, 2 = plain text
        # ------------------------------------------------------------------
        "mailnews.message_display.disable_remote_image" = true;
        "mailnews.display.html_as" = 1;

        # ------------------------------------------------------------------
        # TLS hardening — match firefox.nix
        # ------------------------------------------------------------------
        "security.ssl.require_safe_negotiation" = true;
        "security.tls.version.enable-deprecated" = false;

        # Required for userChrome.css to take effect
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # ------------------------------------------------------------------
        # Add-ons — auto-enable side-loaded XPIs (same rationale as
        # firefox.nix: home-manager drops them in the extensions dir but
        # Thunderbird disables externally-installed addons by default).
        # ------------------------------------------------------------------
        "extensions.autoDisableScopes" = 0;
      };
    };
  };
}
