- clean Release build
- verify Localizable.strings copied
- create DMG
- hdiutil verify
- mount DMG
- smoke test app
- create tag
- upload DMG as GitHub Release asset
- publish SHA-256 checksum


## v0.4.1 Notes

v0.4.1 is a packaging and localization maintenance release.

It verifies that both Localizable.strings and InfoPlist.strings are bundled as proper localized resources.
