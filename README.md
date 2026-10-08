# agy-nix

Nix flake for Google's [Antigravity CLI](https://antigravity.google) (`agy`), which replaced
Gemini CLI. It follows Google's release feed, so it is usually ahead of nixpkgs.

The package is the prebuilt Linux binary from Google, patched to run on NixOS
(`autoPatchelfHook`). It is unfree and not built from source.

## Use

Try it:

```
nix run github:mastratisi/agy-nix        # or: nix run .   in a checkout
```

In a flake-based NixOS config:

```nix
inputs.agy-nix.url = "github:mastratisi/agy-nix";
# ...
nixpkgs.overlays = [ agy-nix.overlays.default ];
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "antigravity-cli" ];
environment.systemPackages = [ pkgs.antigravity-cli ];
```

Systems: `x86_64-linux`, `aarch64-linux` (only x86_64 is tested).

## Auto-update is off

`agy` updates itself, which cannot work in the read-only Nix store. The wrapper sets
`AGY_CLI_DISABLE_AUTO_UPDATE=true` (`--set-default`, so you can override it).
Updates come from this flake instead.

## How it stays current

- `update.sh` reads `<storage>/antigravity-cli/latest` and that version's `manifest.json`,
  and writes `release.json` (version, URL and hash per platform). Needs `jq`, `curl`, `nix`.
- `.github/workflows/update.yml` runs it hourly, builds, checks `agy --version`
  matches, and commits `release.json` if it changed.
- `package.nix` only reads `release.json`; it has no version of its own.

Update by hand: `nix develop -c ./update.sh && nix build`.

## Layout

```
flake.nix      overlay, packages, apps, dev shell
package.nix    the derivation
release.json   version, URLs, hashes (written by update.sh)
update.sh      refresh release.json from Google's feed
```
