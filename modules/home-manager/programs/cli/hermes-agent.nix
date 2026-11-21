{ config, lib, pkgs, inputs, osConfig, ... }:

# Hermes Agent (Nous Research) — CLI plus the Telegram gateway. No backend
# daemon or desktop app. The gateway runs as the `hermes-agent` systemd user
# service; `users.users.sam.linger` (modules/nixos/system.nix) keeps it up
# without a login session. Its bot token comes from sops
# (`hermes/telegram_bot_token`, rendered by the `hermes-env` template in
# modules/nixos/secrets.nix).
#
# Managed mode: `hermes setup` / `hermes config set` / `hermes plugins install`
# are refused at runtime — every setting lives here and applies on rebuild.
#
# Models, all via subscriptions (no API keys):
#   main agent   ChatGPT Plus  built-in `openai-codex` provider; reuses the
#                              Codex CLI login (~/.codex/auth.json, `codex login`)
#   subagents    routed per task by the `advanced-delegation` plugin
#                (model_map), across ChatGPT and Claude Pro. Claude goes
#                through the logged-in Claude Code CLI via the experimental
#                `claude-subscription-directsdk` plugin (`claude auth login`).
let
  hermesHome = config.services.hermes-agent.hermesHome;

  # Plugins from the pinned hermes-official-plugins input, installed as
  # writable copies (see the NOTE in services.hermes-agent below).
  officialPlugins = [
    "claude-subscription-directsdk"
    "advanced-delegation"
  ];

  claude = "claude-subscription-directsdk-experimental";

  # Numeric Telegram user IDs allowed to talk to the bot (get yours from
  # @userinfobot). Not secret, so it lives here rather than in sops.
  telegramAllowedUsers = [ "7114038213" ];

  # Where cron results and other proactive notifications go: a channel the
  # bot (@corporai_bot, display name "Corporal") is a member of.
  telegramHomeChannel = "-1002646688349";
in
{
  imports = [ inputs.hermes-agent.homeManagerModules.default ];

  assertions = [
    {
      assertion = telegramAllowedUsers != [ ] && !(lib.elem "TODO" telegramAllowedUsers);
      message = "hermes-agent.nix: set telegramAllowedUsers to your numeric Telegram user ID(s) before enabling the gateway.";
    }
  ];

  # `hermes` on PATH + HERMES_HOME exported for shells.
  programs.hermes-agent.enable = true;

  services.hermes-agent = {
    enable = true;

    # Telegram gateway (systemd user service). Voice works with defaults:
    # incoming voice notes are transcribed locally (stt: faster-whisper,
    # nothing leaves the machine) and spoken replies use Edge TTS (free, no
    # key) when asked or via `/voice on` in the chat.
    gateway.enable = true;
    environmentFiles = [ osConfig.sops.templates."hermes-env".path ];
    environment = {
      TELEGRAM_ALLOWED_USERS = lib.concatStringsSep "," telegramAllowedUsers;
      TELEGRAM_HOME_CHANNEL = telegramHomeChannel;
    };
    # The gateway unit's PATH is only Hermes + bash/coreutils/git + these.
    # `claude` is required by the Claude subagent route; ffmpeg converts
    # Telegram voice notes (OGG/Opus). Kept explicit: `config.home.packages`
    # recurses, since the Hermes package itself is built from this list.
    extraPackages = with pkgs; [
      unstable.claude-code
      unstable.codex
      ffmpeg
      curl
      gnugrep
      gnused
      findutils
      ripgrep
      jq
      nix
    ];

    # NOTE: not `extraPlugins`. That option symlinks the plugin from the
    # read-only Nix store, and Hermes stages model-provider plugins with
    # shutil.copytree + os.rename (providers/plugin_reload.py). The copy
    # keeps the store's 0555 mode, so moving it to another parent dir fails
    # with EACCES and the provider never registers ("Unknown provider").
    # The activation below installs writable copies instead.

    settings = {
      model = {
        provider = "openai-codex";
        # Hermes' implicit Codex default; documented to work on plans
        # without the GPT-6.2 tier.
        default = "gpt-6-sol";
      };

      # Desktop control (mouse/keyboard/screenshots) isn't needed, and a
      # Telegram-reachable agent shouldn't drive the desktop session.
      agent.disabled_toolsets = [ "computer_use" ];

      # Image generation through the ChatGPT Plus subscription (no API key).
      # This Hermes build has no Google image provider.
      image_gen.provider = "openai-codex";

      plugins = {
        # User plugins are opt-in (bundled ones auto-load). Model-provider
        # plugins need no entry; standalone ones like advanced-delegation do.
        enabled = [ "advanced-delegation" ];

        entries.${claude}.settings = {
          # Refuse requests once the Pro plan limit is hit instead of silently
          # billing paid extra usage (plugin default is "notify" = carry on).
          extra_usage = "stop";
        };
      };

      # Only route names + descriptions reach the model, which picks one per
      # subagent. Listed cheapest first (the plugin's routing skill climbs
      # the list).
      delegation = {
        backend = "model_map";
        backends.model_map = {
          default = "fast";
          options = [
            {
              name = "fast";
              description = "Cheap and quick: lookups, summaries, file searches, simple edits.";
              provider = "openai-codex";
              model = "gpt-5.4-mini";
            }
            {
              name = "standard";
              description = "General coding and multi-step tasks at the main agent's level.";
              provider = "openai-codex";
              model = "gpt-6-sol";
            }
            {
              name = "deep";
              description = "Slow and careful: hard debugging, architecture and design review, long-form writing.";
              provider = claude;
              # Plugin alias for claude-opus-5-5.
              model = "opus";
            }
          ];
        };
      };
    };
  };

  # Persona from the agents repo (SSoT for all assistants). A direct symlink
  # into the working tree, like modules/home-manager/agents.nix does, so
  # edits apply without a rebuild. (`hermesHomeFiles` would copy it into the
  # store instead.)
  home.activation.hermesSoul =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ln -sfn ${lib.escapeShellArg "${config.agents.repoPath}/SOUL.md"} ${lib.escapeShellArg "${hermesHome}/SOUL.md"}
    '';

  home.activation.hermesOfficialPlugins =
    lib.hm.dag.entryAfter [ "writeBoundary" ] (lib.concatMapStrings (name:
      let
        dest = lib.escapeShellArg "${hermesHome}/plugins/${name}";
      in ''
        run rm -rf ${dest}
        run mkdir -p ${lib.escapeShellArg "${hermesHome}/plugins"}
        run cp -r --no-preserve=mode,ownership ${inputs.hermes-official-plugins}/${name} ${dest}
      '' + lib.optionalString (name == "advanced-delegation") ''
        # Upstream's Nix package stamps Hermes as version 0.0.0
        # (nix/hermes-agent.nix: `version ? "0.0.0"`), so this plugin's
        # `requires_hermes: ">=0.22.5"` gate skips it even though the pinned
        # core has the pluggable delegation API it needs
        # (agent/delegation_registry.py). Overriding the version would
        # recompile all of Hermes; dropping the gate from our copy doesn't.
        run sed -i '/^requires_hermes:/d' ${dest}/plugin.yaml
      '') officialPlugins);
}
