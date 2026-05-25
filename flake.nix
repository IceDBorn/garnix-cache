{
  description = "Plasma 6.7 Garnix Cache (NixOS/nixpkgs kdePackages)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/b6ed0c8648df7d7a69d9c1253850ef8a3a1d308f";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ ];
        };
      };

      inherit (pkgs) lib;

      # Escape hatch for `kdePackages` attrs that fail to BUILD on garnix: a
      # linkFarm fails wholesale if any member fails, so list the offending
      # attr names here as garnix reports them. Seeded empty.
      excludedKde = [
        # Missing python3 dev headers (`Python.h`) for its pybind11 build —
        # broken in the 6.7 beta2 audiotube itself, unused on icedos hosts.
        "audiotube"

        # KDE PIM stack broken at this nixpkgs pin: `kmime` is still on Frameworks
        # versioning (6.27.0) while the Gear 26.04.2 PIM apps `find_package(KPim6Mime
        # 6.7.2)` and can't find `KPim6MimeConfig.cmake` — `kmbox` fails configure and
        # the whole reverse-dep closure of `kmime` cascades. Listed = that closure
        # minus `kmime` itself (which builds fine). Unused on icedos hosts (no
        # Kontact/KMail). Drop once nixpkgs realigns kmime to the new naming.
        "akonadi-calendar"
        "akonadi-calendar-tools"
        "akonadi-contacts"
        "akonadi-import-wizard"
        "akonadi-mime"
        "akonadi-search"
        "akonadiconsole"
        "akregator"
        "calendarsupport"
        "eventviews"
        "grantlee-editor"
        "incidenceeditor"
        "kaddressbook"
        "kalarm"
        "kdepim-addons"
        "kdepim-runtime"
        "kgpg"
        "kimap"
        "kitinerary"
        "kleopatra"
        "kmail"
        "kmail-account-wizard"
        "kmbox"
        "kontact"
        "korganizer"
        "libgravatar"
        "libksieve"
        "mailcommon"
        "mailimporter"
        "marknote"
        "mbox-importer"
        "merkuro"
        "messagelib"
        "mimetreeparser"
        "pim-data-exporter"
        "pim-sieve-editor"
        "pimcommon"
        "zanshin"
      ];

      # Guarded lookup: skip non-derivations and attrs that throw on eval or
      # on `drvPath` access.
      tryDrv =
        name:
        let
          rAttr = builtins.tryEval (pkgs.kdePackages.${name} or null);
        in
        if !rAttr.success || rAttr.value == null then
          null
        else if !lib.isDerivation rAttr.value then
          null
        else
          let
            rEval = builtins.tryEval rAttr.value.drvPath;
          in
          if rEval.success then rAttr.value else null;

      kdeNames = lib.filter (n: !(lib.elem n excludedKde)) (builtins.attrNames pkgs.kdePackages);

      kdeDerivations = lib.filter (d: d != null) (map tryDrv kdeNames);
    in
    {
      packages.${system} = {
        default = self.packages.${system}.plasma-bundle;

        plasma-bundle = pkgs.linkFarm "plasma-bundle" (
          map (drv: {
            name = drv.name or "unnamed";
            path = drv;
          }) kdeDerivations
        );

        nixpkgs-passthrough = pkgs.runCommand "nixpkgs-passthrough" { } ''
          mkdir -p $out
          echo "${nixpkgs.rev}" > $out/rev
        '';
      };
    };
}
