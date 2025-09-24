<p align="center">
  <img width="120" height="120" alt="PinterestFix" src="http://storage.server.victorlobe.me/Cydia/packageIcons/PinterestFixIcon.png" />
</p>

<h1 align="center">PinterestFix</h1>

<p align="center">
  An iOS tweak that automatically fixes Pinterest crashes on iOS 5+ by modifying the app's Info.plist version strings.
</p>

<p align="center">
  <a href="https://github.com/victorlobe/PinterestFix/releases/latest">
    <img alt="Download" src="https://img.shields.io/badge/download-latest-blue?logo=apple" />
  </a>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS%205+-007AFF">
</p>

---

## Features

- Automatically fixes Pinterest crashes on iOS 5+
- Modifies CFBundleVersion and CFBundleShortVersionString to "13.28"
- Supports multiple Pinterest bundle identifiers since there are some versions with weird bundle identifiers
- The tweak remembers if Pinterest is already fixed to avoid unnecessary scans

## Requirements

- iOS 5.0+
- Pinterest app version 2.6+ installed
- MobileSubstrate

## How to Use

1. **Install PinterestFix** from Cydia

2. **Respring your device**

3. **Launch Pinterest** - it should now work without crashing!

## To Do

- [ ] Add support for older Pinterest versions (if possible)
- [ ] Create settings panel for manual control

## Behind the Scenes

The tweak runs in SpringBoard and proactively scans for Pinterest installations on launch. It automatically modifies the Info.plist file to set both `CFBundleVersion` and `CFBundleShortVersionString` to "13.28", which prevents Pinterest from crashing on iOS 5+.

## Credits

This tweak is based on a manual fix tutorial that was originally shared in a Discord group. The method involved manually editing Pinterest's Info.plist file with iFile to change the version strings to "13.28".  
I DMed the creator, but he didn’t respond. If he wants, I’ll gladly mention him here.

## Author

Made with ❤️ by Victor Lobe

## License

MIT License – Free to use, share, and modify.