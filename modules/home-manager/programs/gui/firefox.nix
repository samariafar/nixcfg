{ config, pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    languagePacks = [ "en-US" ];

    # ----------------------------------------------------------------------
    # Enterprise policies — applied via policies.json
    # ----------------------------------------------------------------------
    policies = {
      # Privacy / telemetry
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      DisableFirefoxAccounts = true;
      DisableFirefoxStudies = true;
      DisableFormHistory = true;
      DisablePocket = true;
      DisableProfileImport = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "never";
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      PasswordManagerEnabled = false;
      PostQuantumKeyAgreementEnabled = true;

      # Cookies behavior
      Cookies = {
        Behavior = "reject-tracker-and-partition-foreign";
      };

      # Block bypassing security warnings except for invalid certs
      DisableSecurityBypass = {
        InvalidCertificate = false;
        SafeBrowsing = true;
      };

      # Encrypted DNS — Quad9 primary (matches the system-level dnscrypt-proxy2
      # priority order in modules/nixos/networking.nix). Mozilla's policy
      # supports a single ProviderURL; swap to
      # https://mozilla.cloudflare-dns.com/dns-query if Quad9 misbehaves.
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://dns.quad9.net/dns-query";
        Locked = true;
        ExcludedDomains = [ ];
        Fallback = true;
      };

      # Tracking protection (locked + crypto/fingerprinting blocking)
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # DRM (Netflix, etc.)
      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };

      # Restrict where add-ons may be installed from
      InstallAddonsPermission = {
        Allow = [ "https://addons.mozilla.org" ];
        Default = false;
      };

      # Bookmarks toolbar entries
      Bookmarks = [
        {
          Title = "Language Translator";
          URL = "https://translate.google.com";
          Favicon = "https://www.gstatic.com/translate/favicon.ico";
          Placement = "toolbar";
        }
        {
          Title = "Algebra Calculator";
          URL = "https://www.mathway.com";
          Favicon = "https://www.mathway.com/favicon.ico";
          Placement = "toolbar";
        }
        {
          Title = "Currency Rates";
          URL = "https://www.tgju.org/currency";
          Favicon = "https://static.tgju.org/views/default/images/favicon.ico";
          Placement = "toolbar";
        }
        {
          Title = "Image Watermark Remover";
          URL = "https://www.watermarkremover.io";
          Favicon = "https://cdn.pixelbin.io/v2/dummy-cloudname/original/watermarkremover_asset/logo/favicon.ico";
          Placement = "toolbar";
        }
        {
          Title = "Image Background Remover";
          URL = "https://www.remove.bg";
          Favicon = "https://www.remove.bg/favicon.ico";
          Placement = "toolbar";
        }
        {
          Title = "Zoomit";
          URL = "https://www.zoomit.ir";
          Favicon = "https://www.zoomit.ir/favicon.ico";
          Placement = "toolbar";
        }
        {
          Title = "BBC - Persian";
          URL = "https://www.bbc.com/persian";
          Favicon = "https://www.bbc.com/favicon.ico";
          Placement = "toolbar";
        }
        {
          Title = "eBooks Subscription";
          URL = "https://www.scribd.com";
          Favicon = "https://s-f.scribdassets.com/scribd_rebrand.ico";
          Placement = "toolbar";
        }
      ];

      # Per-context tabs (used with Multi-Account Containers)
      Containers = {
        Default = [
          { name = "Anonymous"; icon = "chill"; color = "purple"; }
          { name = "中文";     icon = "circle"; color = "red"; }
          { name = "فارسی";    icon = "circle"; color = "turquoise"; }
        ];
      };

      # mailto handlers — choose between Gmail Personal / Business at click-time
      Handlers = {
        schemes = {
          mailto = {
            action = "useHelperApp";
            ask = true;
            handlers = [
              {
                name = "Gmail - Personal";
                uriTemplate = "https://mail.google.com/mail/u/0/?extsrc=mailto&url=%s";
              }
              {
                name = "Gmail - Business";
                uriTemplate = "https://mail.google.com/mail/u/1/?extsrc=mailto&url=%s";
              }
            ];
          };
        };
      };

      # Suppress topsites / sponsored suggestions on the new tab
      FirefoxHome = {
        TopSites = false;
        Locked = true;
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
        ImproveSuggest = false;
        Locked = true;
      };

      # Localhost dev exemptions for HTTPS-only mode
      HttpAllowlist = [
        "http://localhost"
        "http://localhost:3000"
        "http://localhost:8000"
        "http://localhost:8080"
        "http://localhost:9001"
      ];

      Homepage = {
        Locked = true;
        StartPage = "previous-session";
      };

      # Locked / preset prefs
      Preferences = {
        "findbar.highlightAll" = {
          Value = true;
          Status = "user";
        };
        "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = {
          Value = false;
          Status = "user";
        };
        "security.ssl.require_safe_negotiation" = {
          Value = true;
          Status = "locked";
        };
        "security.tls.version.enable-deprecated" = {
          Value = false;
          Status = "locked";
        };
        # Required for userChrome.css to take effect
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };

        # Send Global Privacy Control (CCPA / EU "do not sell my data")
        "privacy.globalprivacycontrol.enabled" = {
          Value = true;
          Status = "locked";
        };

        # Send DNT header
        "privacy.donottrackheader.enabled" = {
          Value = true;
          Status = "locked";
        };

        # Suppress in-browser feature/addon recommendations
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = {
          Value = false;
          Status = "locked";
        };

        # Skip the EncryptedMediaExtensions first-run prompt
        "browser.eme.ui.firstContentShown" = {
          Value = true;
          Status = "locked";
        };

        # Skip the about:welcome wizard on fresh profiles
        "browser.aboutwelcome.didSeeFinalScreen" = {
          Value = true;
          Status = "user";
        };

        # Confirm before closing a window/Ctrl+Q with multiple tabs open
        "browser.tabs.warnOnClose" = {
          Value = true;
          Status = "user";
        };
      };

      WebsiteFilter = {
        Block = [ ];
      };

      # Extensions installed via policy (install_url) — used for addons that
      # are NOT in `pkgs.nur.repos.rycee.firefox-addons`. Verified-NUR addons
      # are declared declaratively below in profiles.default.extensions.packages.
      #
      # ATTENTION: If any of the NUR names below turn out to be wrong, move
      # the failing addon to this block as a fallback.
      ExtensionSettings = {
        "3rdparty" = { };

        # Emoji (Saverio Morelli) — likely not in NUR
        "emoji@saveriomorelli.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/emoji-sav/latest.xpi";
          default_area = "menupanel";
        };

        # Giphy for Firefox — verify NUR availability
        "gt@giphy.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/giphy-for-firefox/latest.xpi";
          default_area = "menupanel";
        };

        # Undo Close Tab Button — verify NUR availability
        "{4853d046-c5a3-436b-bc36-220fd935ee1d}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/undoclosetabbutton/latest.xpi";
          default_area = "navbar";
          private_browsing = true;
        };

        # Private-browsing opt-in for NUR-managed addons. NUR drops the XPIs
        # via profiles.default.extensions.packages; these entries only flip
        # the per-extension privateBrowsingAllowed flag without re-installing.
        "{036a55b4-5e72-4d05-a06c-cba2dfcc134a}".private_browsing = true; # Translate Web Pages
        "{1018e4d6-728f-4b20-ad56-37578a4de76b}".private_browsing = true; # Flagfox
        "{3c078156-979c-498b-8990-85f7987dd929}".private_browsing = true; # Sidebery
        "simple-translate@sienori".private_browsing = true;
        "uBlock0@raymondhill.net".private_browsing = true;

        # Markdown Reader — render .md files in-browser. GUID confirmed via
        # AMO API (https://addons.mozilla.org/api/v5/addons/addon/markdown-reader-ext/).
        "{f3ee08f8-d4d8-4095-8096-4bb784d082f9}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/markdown-reader-ext/latest.xpi";
          default_area = "menupanel";
        };

        # NetFix — PiP for Netflix. GUID confirmed via AMO API.
        "netfix-pip@firefox" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/netfix/latest.xpi";
          default_area = "menupanel";
        };
      };
    };

    # ----------------------------------------------------------------------
    # Profile (single, default)
    # ----------------------------------------------------------------------
    profiles.default = {
      id = 0;

      # Auto-enable side-loaded addons (NUR/home-manager drops XPIs into the
      # extensions dir; Firefox would otherwise disable them as "installed by
      # an external program" until manually approved via a prompt).
      settings = {
        "extensions.autoDisableScopes" = 0;
      };

      # userChrome.css — hides the bookmark star, hides sidebar header,
      # animates native tabs strip (toggled by zero-width-space title preface).
      userChrome = builtins.readFile ./firefox/userChrome.css;

      # Declaratively-managed addons via NUR.
      # ATTENTION: Names below are best-effort guesses; if a build fails with
      # "attribute 'X' missing", check `nix search nur#repos.rycee.firefox-addons`
      # and either fix the name or move the addon to ExtensionSettings above.
      extensions = {
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          bitwarden
          flagfox
          languagetool
          metamask
          multi-account-containers
          raindropio
          return-youtube-dislikes
          sidebery
          simple-translate
          sponsorblock
          temporary-containers
          translate-web-pages # AMO: traduzir-paginas-web
          ublock-origin
        ];
      };

      # Custom search engines / bang-style aliases
      search = {
        force = true;
        engines = {
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "channel"; value = "unstable"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "Docker Hub" = {
            urls = [{
              template = "https://hub.docker.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }];

            icon = "https://www.docker.com/wp-content/uploads/2024/02/cropped-docker-logo-favicon-32x32.png";
            definedAliases = [ "@dh" ];
          };

          "Etherscan" = {
            urls = [{
              template = "https://etherscan.io/address/{searchTerms}";
            }];

            icon = "https://etherscan.io/images/favicon3.ico";
            definedAliases = [ "@es" ];
          };

          "WHOIS" = {
            urls = [{
              template = "https://client.rdap.org";
              params = [
                { name = "type"; value = "domain"; }
                { name = "object"; value = "{searchTerms}"; }
              ];
            }];

            icon = "https://about.rdap.org/assets/icon.png";
            definedAliases = [ "@whois" ];
          };

          "Open Source Alternatives" = {
            urls = [{
              template = "https://www.opensourcealternative.to";
              params = [
                { name = "searchTerm"; value = "{searchTerms}"; }
              ];
            }];

            icon = "https://www.opensourcealternative.to/favicon.ico";
            definedAliases = [ "@at" ];
          };
        };
      };
    };
  };
}
