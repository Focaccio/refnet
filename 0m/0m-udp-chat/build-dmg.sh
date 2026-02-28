#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
STAGE_A_DIR="$BUILD_DIR/stage-a"
STAGE_Z_DIR="$BUILD_DIR/stage-z"
CACHE_DIR="${SWIFT_MODULE_CACHE:-$ROOT_DIR/.swift-module-cache}"
VERSION="${1:-v2}"
DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET:-12.0}"
ARCHS="${ARCHS:-arm64 x86_64}"

A_SRC="$ROOT_DIR/a-side-udp-chat-${VERSION}.swift"
Z_SRC="$ROOT_DIR/z-side-udp-chat-${VERSION}.swift"

A_APP_NAME="A-Side UDP Chat"
Z_APP_NAME="Z-Side UDP Chat"
A_BUNDLE_ID="com.refnet.udpp2pchat.a"
Z_BUNDLE_ID="com.refnet.udpp2pchat.z"

A_DMG_NAME="a-side-udp-chat-${VERSION}-macos.dmg"
Z_DMG_NAME="z-side-udp-chat-${VERSION}-macos.dmg"
A_VOL_NAME="A-Side UDP Chat ${VERSION}"
Z_VOL_NAME="Z-Side UDP Chat ${VERSION}"

if [[ ! -f "$A_SRC" ]]; then
  echo "Missing source file: $A_SRC" >&2
  exit 1
fi

if [[ ! -f "$Z_SRC" ]]; then
  echo "Missing source file: $Z_SRC" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR" "$DIST_DIR" "$CACHE_DIR"
rm -rf "$STAGE_A_DIR" "$STAGE_Z_DIR"
mkdir -p "$STAGE_A_DIR" "$STAGE_Z_DIR"

build_app() {
  local stage_dir="$1"
  local app_name="$2"
  local bundle_id="$3"
  local src_file="$4"

  local app_dir="$stage_dir/${app_name}.app"
  local macos_dir="$app_dir/Contents/MacOS"
  local resources_dir="$app_dir/Contents/Resources"
  local tmp_build_dir="$BUILD_DIR/tmp-${app_name// /-}"
  local exe_name="$app_name"

  mkdir -p "$macos_dir" "$resources_dir" "$tmp_build_dir"
  rm -f "$tmp_build_dir/$exe_name"-*

  local built_arches=()
  for arch in $ARCHS; do
    local out_bin="$tmp_build_dir/$exe_name-$arch"
    swiftc \
      -module-cache-path "$CACHE_DIR" \
      -target "$arch-apple-macos$DEPLOYMENT_TARGET" \
      -framework Cocoa \
      "$src_file" \
      -o "$out_bin"
    built_arches+=("$out_bin")
  done

  if [[ "${#built_arches[@]}" -gt 1 ]]; then
    lipo -create "${built_arches[@]}" -output "$macos_dir/$exe_name"
  else
    cp "${built_arches[0]}" "$macos_dir/$exe_name"
  fi
  chmod +x "$macos_dir/$exe_name"

  cat > "$app_dir/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${exe_name}</string>
  <key>CFBundleIdentifier</key>
  <string>${bundle_id}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${app_name}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>${DEPLOYMENT_TARGET}</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

  if [[ -n "${DEVELOPER_ID_APP:-}" ]]; then
    codesign --force --deep --options runtime --sign "$DEVELOPER_ID_APP" "$app_dir"
  fi
}

write_readme() {
  local stage_dir="$1"
  local app_name="$2"
  cat > "$stage_dir/README.txt" <<TXT
${app_name} ${VERSION} for macOS

Contents:
- ${app_name}.app

Notes:
- If macOS warns the app is from an unidentified developer, right-click app and choose Open.
- For wide distribution, sign with Developer ID and notarize.
TXT
}

build_app "$STAGE_A_DIR" "$A_APP_NAME" "$A_BUNDLE_ID" "$A_SRC"
build_app "$STAGE_Z_DIR" "$Z_APP_NAME" "$Z_BUNDLE_ID" "$Z_SRC"
write_readme "$STAGE_A_DIR" "$A_APP_NAME"
write_readme "$STAGE_Z_DIR" "$Z_APP_NAME"

rm -f "$DIST_DIR/$A_DMG_NAME" "$DIST_DIR/$Z_DMG_NAME"
hdiutil create -volname "$A_VOL_NAME" -srcfolder "$STAGE_A_DIR" -ov -format UDZO "$DIST_DIR/$A_DMG_NAME" >/dev/null
hdiutil create -volname "$Z_VOL_NAME" -srcfolder "$STAGE_Z_DIR" -ov -format UDZO "$DIST_DIR/$Z_DMG_NAME" >/dev/null

if [[ -n "${DEVELOPER_ID_APP:-}" ]]; then
  codesign --force --sign "$DEVELOPER_ID_APP" "$DIST_DIR/$A_DMG_NAME"
  codesign --force --sign "$DEVELOPER_ID_APP" "$DIST_DIR/$Z_DMG_NAME"
fi

echo "Created: $DIST_DIR/$A_DMG_NAME"
echo "Created: $DIST_DIR/$Z_DMG_NAME"
