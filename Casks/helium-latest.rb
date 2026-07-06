# Always-newest variant: no version pinning, no checksum. Resolves the latest
# release tag at install time. Use this if you'd rather not bump helium.rb per
# release. Trade-off: no checksum pinning (sha256 :no_check).
require "download_strategy"

class GitHubLatestReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    @owner = "megalithic"
    @repo = "helium-macos-releases"
  end

  private

  def asset
    @asset ||= begin
      release = GitHub::API.open_rest(
        GitHub.url_to("repos", @owner, @repo, "releases", "latest"),
      )
      found = release.fetch("assets").find { |a| a.fetch("name").match?(/_arm64-macos\.dmg$/) }
      raise CurlDownloadStrategyError, "no arm64 DMG in latest release" unless found

      found
    end
  end

  def resolve_url_basename_time_file_size(_url, timeout: nil)
    [asset.fetch("url"), asset.fetch("name"), Time.parse(asset.fetch("updated_at")),
     asset.fetch("size"), asset.fetch("content_type"), false]
  end

  def _fetch(url:, resolved_url:, timeout:)
    token = GitHub::API.credentials
    header = ["Accept: application/octet-stream"]
    header << "Authorization: Bearer #{token}" unless token.to_s.empty?
    curl_download(resolved_url, to: temporary_path, try_partial: @try_partial, timeout:, header:)
  end
end

cask "helium-latest" do
  version :latest
  sha256 :no_check

  url "https://github.com/megalithic/helium-macos-releases/releases/latest",
      using:    GitHubLatestReleaseDownloadStrategy,
      verified: "github.com/megalithic/helium-macos-releases/"
  name "Helium (latest)"
  desc "Ungoogled Chromium (Helium), signed + notarized, with Widevine CDM — always newest"
  homepage "https://github.com/megalithic/helium-macos-releases"

  conflicts_with cask: "megalithic/helium/helium"
  depends_on arch: :arm64

  app "Helium.app"

  zap trash: [
    "~/Library/Application Support/net.imput.helium",
    "~/Library/Caches/net.imput.helium",
    "~/Library/Preferences/net.imput.helium.plist",
    "~/Library/Saved Application State/net.imput.helium.savedState",
  ]
end
