Steps to release
================

  1. Write release notes.
  2. Bump version in Info.plist.
  3. Compile with Release target.
  4. Compress built app bundle.
  5. Sign update (sparkle/Signing Tools/sign_update.rb).
  6. Update appcast.xml:
     - Version
     - Release notes
     - Size of zip
     - Signature
     - Location of update
     - Time of release
  7. Update index.html.
  8. Upload Acquire\_x.y.z.zip and release notes.
  9. Upload index.html and appcast.xml.
  10. Commit to master branch and tag with version.
