# Custom download strategy: resolves a private GitHub release asset through the
# authenticated API only at download time, so loading the cask makes no API
# calls and a normal releases/download URL stays in the `url` stanza.
#
# Auth uses GitHub::API.credentials (checks HOMEBREW_GITHUB_API_TOKEN, then gh
# CLI token, then keychain). For a private repo you must have one of those.
require "download_strategy"

class GitHubPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    match = url.match %r{^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$}
    raise CurlDownloadStrategyError, "not a GitHub release asset URL: #{url}" unless match

    @owner, @repo, @tag, @filename = match.captures
  end

  private

  def asset
    @asset ||= begin
      release = GitHub::API.open_rest(
        GitHub.url_to("repos", @owner, @repo, "releases", "tags", @tag),
        scopes: ["repo"],
      )
      found = release.fetch("assets").find { |a| a.fetch("name") == @filename }
      raise CurlDownloadStrategyError, "no asset named #{@filename} in #{@tag}" unless found

      found
    end
  end

  def resolve_url_basename_time_file_size(_url, timeout: nil)
    [asset.fetch("url"), @filename, Time.parse(asset.fetch("updated_at")),
     asset.fetch("size"), asset.fetch("content_type"), false]
  end

  def _fetch(url:, resolved_url:, timeout:)
    token = GitHub::API.credentials
    header = ["Accept: application/octet-stream"]
    header << "Authorization: Bearer #{token}" unless token.to_s.empty?
    curl_download(resolved_url, to: temporary_path, try_partial: @try_partial, timeout:, header:)
  end
end

cask "helium" do
  # arm64-only build. To pin an older release: `brew install --cask helium --version=0.14.2.1`
  # is not supported for casks; instead bump `version`/`sha256` below or check out an
  # older tap commit. `version :latest` (see helium-latest.rb) tracks newest automatically.
  version "0.21.1.1"
  sha256 "5f76852caca4554db174b9874510556ac7dd8016f5a68ce09cb3da80b29d90ee"

  url "https://github.com/megalithic/helium-macos-releases/releases/download/#{version}/helium_#{version}_arm64-macos.dmg",
      using:    GitHubPrivateReleaseDownloadStrategy,
      verified: "github.com/megalithic/helium-macos-releases/"
  name "Helium"
  desc "Ungoogled Chromium (Helium), signed + notarized, with Widevine CDM"
  homepage "https://github.com/megalithic/helium-macos-releases"

  livecheck do
    url :url
    strategy :github_releases do |json, regex|
      json.filter_map do |release|
        next if release["draft"] || release["prerelease"]

        release["tag_name"]&.[](regex, 1)
      end
    end
  end

  depends_on arch: :arm64

  app "Helium.app"

  zap trash: [
    "~/Library/Application Support/net.imput.helium",
    "~/Library/Caches/net.imput.helium",
    "~/Library/Preferences/net.imput.helium.plist",
    "~/Library/Saved Application State/net.imput.helium.savedState",
  ]
end
