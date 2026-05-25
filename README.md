# icedos-plasma67-cache

Public flake repo whose only purpose is to drive [garnix.io](https://garnix.io/) to pre-build the KDE Plasma 6.7-beta closure from K900's draft nixpkgs PR ([NixOS/nixpkgs#520160](https://github.com/NixOS/nixpkgs/pull/520160)) and expose the result via `cache.garnix.io` so icedos hosts pull binaries instead of locally compiling for 6-12 hours.

## How icedos consumes this

In `icedos/core/flake.nix`, add input:

```nix
inputs.plasma67-cache.url = "github:IceDBorn/plasma67-cache";
```

Overlay `kdePackages` from this input's pinned nixpkgs. Add `cache.garnix.io` as a substituter with its public key. See plan at `/home/ice/.claude/plans/context-ref-file-home-ice-projects-iced-purrfect-panda.md`.

## Lifecycle

Discard this repo once [NixOS/nixpkgs#520160](https://github.com/NixOS/nixpkgs/pull/520160) merges to master and the resulting commit lands in the `nixos-unstable` channel (then `cache.nixos.org` carries the same store paths).

## Pin

`nixpkgs.url` points at K900's PR head commit `788a6c3a28b78c647ceb5c69d9346845985df77b` on branch `K900:plasma-6.7`. Bump the rev when K900 force-pushes new fixes to the PR.
