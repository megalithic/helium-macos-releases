# helium-macos-releases

Signed + notarized macOS releases of [Helium](https://github.com/imputnet/helium-macos), built from [megalithic/helium-macos](https://github.com/megalithic/helium-macos) with Widevine injected.

See Releases for DMGs.

## Install via Homebrew cask (recommended)

This repo doubles as a Homebrew tap. Because it's **private**, `brew` needs a
GitHub token with read access — set `HOMEBREW_GITHUB_API_TOKEN`, or have the `gh`
CLI authenticated (the cask's download strategy reads either).

```sh
brew tap megalithic/helium https://github.com/megalithic/helium-macos-releases
brew install --cask helium            # pinned version (helium.rb), checksum-verified
# or, always newest without per-release bumps:
brew install --cask helium-latest     # tracks latest release, sha256 :no_check
```

The DMG (app + container) is Developer ID signed + notarized, so it installs to
`/Applications/Helium.app` with no Gatekeeper prompt and Widevine DRM works.

- `helium.rb` — pin `version`/`sha256`; `brew livecheck helium` detects new releases; bump both to update.
- `helium-latest.rb` — resolves the newest release at install time.

## aqua / mise aqua backend — not supported

`mise use aqua:megalithic/helium-macos-releases` does **not** work. mise's aqua
backend is a Rust reimplementation without `dmg` support (a DMG is treated as a
raw file and never mounted). Even upstream aqua-CLI only extracts a CLI binary
to PATH, not a GUI app to `/Applications`. See `registry.yaml` for details.
Use the Homebrew cask instead.
