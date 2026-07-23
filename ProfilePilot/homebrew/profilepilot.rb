cask "profilepilot" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHASUM_256_OF_DMG"

  url "https://github.com/YOURUSER/ProfilePilot/releases/download/v#{version}/ProfilePilot-#{version}.dmg",
      verified: "github.com/YOURUSER/ProfilePilot"
  name "ProfilePilot"
  desc "Native macOS workspace + browser-profile launcher"
  homepage "https://profilepilot.app"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "ProfilePilot.app"

  zap trash: [
    "~/Applications/ProfilePilot",
    "~/Library/Application Support/ProfilePilot",
    "~/Library/Preferences/com.profilepilot.app.plist",
    "~/Library/Caches/com.profilepilot.app",
    "~/Library/HTTPStorages/com.profilepilot.app",
  ]
end
