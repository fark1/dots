{ config, pkgs, lib, ... }:

let
  # "Dark Theme" (AMO slug: perfectdarktheme) - the static theme extension
  # actually active in the real profile (extensions.activeThemeID). Not in
  # NUR's curated firefox-addons list (niche, ~900 daily users), so fetched
  # directly from AMO instead of pulling in NUR as a whole extra input for
  # one small theme. Static theme, no code, just color values - low risk.
  perfectDarkTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "perfectdarktheme";
    version = "1.1";

    src = pkgs.fetchurl {
      url = "https://addons.mozilla.org/firefox/downloads/file/3879908/perfectdarktheme-1.1.xpi";
      sha256 = "a86f1b27e244d1d6330a2202da4789f302f4a8d9dda7e4157d239402a14d60bc";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out
      cp $src "$out/{47a97a22-13b8-410a-9bd8-2bf689498872}.xpi"
    '';

    meta = {
      description = "Dark Theme - static LibreWolf/Firefox theme";
      homepage = "https://addons.mozilla.org/firefox/addon/perfectdarktheme/";
    };
  };
in
{
  programs.librewolf = {
    enable = true;

    profiles.default = {
      isDefault = true;

      # Curated from the real prefs.js - only settings that read as genuine
      # deliberate choices, not LibreWolf's own hardened defaults or
      # ephemeral runtime state (timestamps, telemetry cache, sync
      # checkpoints, toolbar layout, etc all excluded).

      userChrome = ''
        :root {
          --toolbar-bgcolor: #101419 !important;
          --toolbar-color: #b6becc !important;
          --lwt-accent-color: #0e1217 !important;
          --lwt-accent-color-inactive: #0d1014 !important;
          --toolbar-field-background-color: #15191e !important;
          --toolbar-field-color: #b6becc !important;
          --toolbar-field-focus-background-color: #101419 !important;
          --tab-line-color: #70a5eb !important;
          --lwt-toolbar-field-highlight: #70a5eb !important;
          --lwt-toolbar-field-highlight-text: #101419 !important;
          --arrowpanel-background: #101419 !important;
          --arrowpanel-color: #b6becc !important;
          --arrowpanel-border-color: #70a5eb !important;
          --button-bgcolor: #282e33 !important;
          --sidebar-background-color: #22194d !important;
          --sidebar-text-color: #b6becc !important;
        }

        /* Fallback: hit chrome elements directly so theming doesn't
           depend on extensions.activeThemeID actually taking effect. */
        #navigator-toolbox,
        #TabsToolbar,
        #nav-bar,
        #PersonalToolbar {
          background-color: #101419 !important;
          color: #b6becc !important;
        }

        #tabbrowser-tabs .tabbrowser-tab {
          color: #b6becc !important;
        }

        #urlbar,
        #searchbar {
          background-color: #15191e !important;
          color: #b6becc !important;
        }
      '';

      settings = {
        # Auto-enable extensions.packages below without a manual approval
        # step (recommended by the module docs for declarative extensions).
        "extensions.autoDisableScopes" = 0;
        # Explicitly activate the dark theme extension - without this,
        # lwtheme never gets set to true and most --lwt-*/--toolbar-*
        # variables in userChrome are silently ignored (only the urlbar
        # picks them up unconditionally, which is why only that changed).
        "extensions.activeThemeID" = "{47a97a22-13b8-410a-9bd8-2bf689498872}";
        # Forces websites to render dark regardless of system preference.
        "layout.css.prefers-color-scheme.content-override" = 0;
        # LibreWolf defaults this to true; explicitly off here since it was
        # off in the real profile (likely because RFP breaks some sites).
        "privacy.resistFingerprinting" = false;
        "sidebar.visibility" = "hide-sidebar";
        "privacy.sanitize.sanitizeOnShutdown" = false;
      };

      extensions.packages = [ perfectDarkTheme ];

      search = {
        force = true;
        default = "ddg";
        engines = {
          google.metaData.hidden = true;
          bing.metaData.hidden = true;
          amazondotcom.metaData.hidden = true;
          ebay.metaData.hidden = true;
          twitter.metaData.hidden = true;
        };
      };
    };
  };
}