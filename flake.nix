{
  description = "My Garnix Cache";
  inputs.nixpkgs.url = "github:thefossguy/nixpkgs/ba7749151e18920b00e74701df5bf7cbab83fc20";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;

        overlays = [
          (_final: prev: {
            cosmic-comp = prev.cosmic-comp.overrideAttrs (old: {
              doCheck = false;
              patches = (old.patches or [ ]) ++ [
                ./patches/cosmic-comp/dmem-foreground-booster.patch
                ./patches/cosmic-comp/fix-tiling-hint-clipping.patch
                ./patches/cosmic-comp/per-window-keyboard-layout.patch
              ];
            });

            cosmic-applets = prev.cosmic-applets.overrideAttrs (old: {
              doCheck = false;

              patches = (old.patches or [ ]) ++ [
                ./patches/cosmic-applets/steam-game-icon-matcher.patch
                ./patches/cosmic-applets/stable-clock-width.patch
              ];

              postPatch =
                (old.postPatch or "")
                + ''
                  if grep -q 'self.core.applet.text(visible_str)' cosmic-applet-time/src/window.rs; then
                    substituteInPlace cosmic-applet-time/src/window.rs \
                      --replace-fail \
                      'self.core.applet.text(visible_str)' \
                      'container(column![space::vertical().height(Length::Fixed(2.25)), self.core.applet.text(visible_str)]).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32)).align_y(Alignment::Center)'

                    substituteInPlace cosmic-applet-time/src/window.rs \
                      --replace-fail \
                      '.class(cosmic::theme::Text::Color(Color::TRANSPARENT))' \
                      '.class(cosmic::theme::Text::Color(Color::TRANSPARENT)).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32))'
                  else
                    substituteInPlace cosmic-applet-time/src/window.rs \
                      --replace-fail \
                      'self.core.applet.text(formatted_date)' \
                      'container(column![space::vertical().height(Length::Fixed(2.25)), self.core.applet.text(formatted_date)]).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32)).align_y(Alignment::Center)'
                  fi

                  substituteInPlace cosmic-applet-workspaces/src/components/app.rs \
                    --replace-fail \
                    'self.core.applet.text(&w.name).font(cosmic::font::bold())' \
                    'container(column![space::vertical().height(Length::Fixed(2.25)), self.core.applet.text(&w.name).font(cosmic::font::bold())]).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32)).align_y(Alignment::Center)'
                ''
                + ''
                  if grep -q 'self.core.applet.text(visible_str)' cosmic-applet-time/src/window.rs; then
                    substituteInPlace cosmic-applet-time/src/window.rs \
                      --replace-fail \
                      'self.core.applet.text(visible_str)' \
                      'self.core.applet.text(visible_str).font(cosmic::font::bold())'
                  else
                    substituteInPlace cosmic-applet-time/src/window.rs \
                      --replace-fail \
                      'self.core.applet.text(formatted_date)' \
                      'self.core.applet.text(formatted_date).font(cosmic::font::bold())'
                  fi

                  substituteInPlace cosmic-applet-time/src/window.rs \
                    --replace-fail \
                    'self.core.applet.text(piece.to_owned()).into()' \
                    'self.core.applet.text(piece.to_owned()).font(cosmic::font::bold()).into()'

                  substituteInPlace cosmic-applet-time/src/window.rs \
                    --replace-fail \
                    'self.core.applet.text(p.to_owned()).into()' \
                    'self.core.applet.text(p.to_owned()).font(cosmic::font::bold()).into()'

                  substituteInPlace cosmic-applet-input-sources/src/lib.rs \
                    --replace-fail \
                    'let input_source_text = self.core.applet.text(applet_text);' \
                    'let input_source_text = self.core.applet.text(applet_text).font(cosmic::font::bold());'
                ''
                + ''
                  iced_rs="$cargoDepsCopy"/source-git-*/libcosmic-*/src/theme/style/iced.rs
                  substituteInPlace $iced_rs \
                    --replace-fail \
                    'Button::Card => corner_radii.radius_xs.into(),' \
                    'Button::Card => corner_radii.radius_s.into(),'
                '';
            });

            cosmic-osd =
              (prev.cosmic-osd.overrideAttrs (old: {
                doCheck = false;
                patches = (old.patches or [ ]) ++ [
                  ./patches/cosmic-osd/keyboard-layout-osd.patch
                ];
              })).overrideAttrs
                (old: {
                  postPatch = (old.postPatch or "") + ''
                    substituteInPlace src/components/osd_indicator.rs \
                      --replace-fail \
                      'Duration::from_secs(3)' \
                      'Duration::from_millis(750)'
                  '';
                });

            cosmic-settings-daemon = prev.cosmic-settings-daemon.overrideAttrs (old: {
              doCheck = false;
              patches = (old.patches or [ ]) ++ [
                ./patches/cosmic-settings-daemon/keyboard-layout-osd.patch
                ./patches/cosmic-settings-daemon/ddc-skip-capabilities-gate.patch
              ];
            });

            cosmic-notifications = prev.cosmic-notifications.overrideAttrs (oldAttrs: {
              doCheck = false;
              postPatch = (oldAttrs.postPatch or "") + ''
                iced_rs="$cargoDepsCopy"/source-git-*/libcosmic-*/src/theme/style/iced.rs
                substituteInPlace $iced_rs \
                  --replace-fail \
                  'Button::Card => corner_radii.radius_xs.into(),' \
                  'Button::Card => corner_radii.radius_s.into(),'
              '';
            });

            # NixOS/nixpkgs#524857 declares the wrong sha256 for the
            # pop-os/cosmic-panel epoch-1.0.14 tarball; upstream serves
            # sha256-6Ny38Eyz+z2Hvj8AUIDbN1Z+ZntA8+SlKAQmPF1jR3Q= but the PR
            # baked sha256-iUjrm/ZnDV2y+B7SLFJ59KRPJkkGKLKwW9qHUsfo8aw=.
            # Override only src.outputHash so the fixed-output drv accepts
            # the real tarball without changing the fetch script (matches
            # icedos's overlay; using prev.fetchFromGitHub directly would
            # pick a different fetcher than icedos and drift the drv hash).
            cosmic-panel = prev.cosmic-panel.overrideAttrs (old: {
              src = old.src.overrideAttrs (_: {
                outputHash = "sha256-6Ny38Eyz+z2Hvj8AUIDbN1Z+ZntA8+SlKAQmPF1jR3Q=";
              });
              # PR-baked cargoHash matched the wrong tarball; corrected src
              # produces a different cargo vendor. cargoDeps wraps a FOD
              # (vendorStaging) — the FOD owns `outputHash`, so override
              # there, not on the runCommand wrapper.
              cargoDeps = old.cargoDeps.overrideAttrs (oa: {
                vendorStaging = oa.vendorStaging.overrideAttrs (_: {
                  outputHash = "sha256-6E+bAi1f6gOZh64wyvLMKZiZNlMexPV+ZzS3riOx9xM=";
                });
              });
            });

            # cosmic-idle vendor-staging is non-deterministic upstream:
            # `.git` directory leaks into the FOD, so cargoDeps hash differs
            # per build (NixOS/nixpkgs#524670, fix in #525255 — both open).
            # No override pattern can fix it — local and garnix derive
            # different hashes regardless of pinned value. Excluded from
            # cosmic-bundle below so the rest of the closure still caches.
          })
        ];
      };

      inherit (pkgs) lib;

      # Mirror the icedos overlay set (config/.state/flake.nix:200-224) so
      # the cache covers exactly what the consumer overlay rewrites — no
      # more, no less. Skipping the broad `lib.hasPrefix "cosmic-"` glob
      # avoids paying garnix CPU on the dozens of cosmic-ext-* extension
      # crates that ship in nixpkgs but never see the PR #524857 overlay
      # on icedos hosts (so they'd build to a hash the user never asks for).
      #
      # Exclusions vs. the full overlay set:
      #   - cosmic-idle: vendor-staging non-determinism upstream
      #     (NixOS/nixpkgs#524670 / fix #525255 — both open). Cannot be
      #     cached cross-machine until the .git leak is plugged.
      #   - cosmic-applibrary / cosmic-files / cosmic-initial-setup /
      #     cosmic-launcher: unused on the user's icedos hosts.
      excludedCosmic = [
        "cosmic-applibrary"
        "cosmic-files"
        "cosmic-idle"
        "cosmic-initial-setup"
        "cosmic-launcher"
      ];

      bundleNames =
        let
          icedosCosmic = [
            "cosmic-applets"
            "cosmic-applibrary"
            "cosmic-bg"
            "cosmic-comp"
            "cosmic-edit"
            "cosmic-files"
            "cosmic-greeter"
            "cosmic-icons"
            "cosmic-idle"
            "cosmic-initial-setup"
            "cosmic-launcher"
            "cosmic-notifications"
            "cosmic-osd"
            "cosmic-panel"
            "cosmic-player"
            "cosmic-randr"
            "cosmic-screenshot"
            "cosmic-session"
            "cosmic-settings"
            "cosmic-settings-daemon"
            "cosmic-store"
            "cosmic-term"
            "cosmic-wallpapers"
            "cosmic-workspaces-epoch"
          ];
          activeCosmic = lib.filter (n: !(lib.elem n excludedCosmic)) icedosCosmic;
          extras = [
            "pop-gtk-theme"
            "pop-icon-theme"
            "xdg-desktop-portal-cosmic"
            "cosmic-ext-tweaks"
          ];
        in
        activeCosmic ++ extras;

      tryDrv =
        name:
        let
          rAttr = builtins.tryEval pkgs.${name};
        in
        if !rAttr.success then
          null
        else if !lib.isDerivation rAttr.value then
          null
        else
          let
            rEval = builtins.tryEval rAttr.value.drvPath;
          in
          if rEval.success then rAttr.value else null;

      cosmicEntries = lib.filter (e: e.value != null) (
        map (n: {
          name = n;
          value = tryDrv n;
        }) bundleNames
      );

      cosmicDerivations = map (e: e.value) cosmicEntries;
    in
    {
      packages.${system} = {
        default = self.packages.${system}.cosmic-bundle;

        cosmic-bundle = pkgs.linkFarm "cosmic-bundle" (
          map (drv: {
            name = drv.name or "unnamed";
            path = drv;
          }) cosmicDerivations
        );

        nixpkgs-passthrough = pkgs.runCommand "nixpkgs-passthrough" { } ''
          mkdir -p $out
          echo "${nixpkgs.rev}" > $out/rev
        '';
      };
    };
}
