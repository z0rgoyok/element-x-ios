#!/bin/sh

setup_tich_signing() {
  KEYCHAIN_PATH="$RUNNER_TEMP/tich-connect-signing.keychain-db"
  KEYCHAIN_PASSWORD="$(openssl rand -hex 32)"
  CERTIFICATE_PATH="$RUNNER_TEMP/tich-connect-distribution.p12"
  AUTH_KEY_PATH="$RUNNER_TEMP/AuthKey_${TICH_APP_STORE_CONNECT_KEY_ID}.p8"

  security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

  printf '%s' "$TICH_DISTRIBUTION_P12_BASE64" | base64 --decode > "$CERTIFICATE_PATH"
  security import "$CERTIFICATE_PATH" -k "$KEYCHAIN_PATH" \
    -P "$TICH_DISTRIBUTION_P12_PASSWORD" -T /usr/bin/codesign
  security set-key-partition-list -S apple-tool:,apple:,codesign: \
    -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  OLD_KEYCHAINS="$(security list-keychains -d user | tr -d '"')"
  # Existing keychain paths come from Security; none contain whitespace.
  # shellcheck disable=SC2086
  set -- $OLD_KEYCHAINS
  security list-keychains -d user -s "$KEYCHAIN_PATH" "$@"

  printf '%s\n' "$TICH_APP_STORE_CONNECT_PRIVATE_KEY" > "$AUTH_KEY_PATH"
  chmod 0600 "$AUTH_KEY_PATH" "$CERTIFICATE_PATH"
  mkdir -p "$HOME/.private_keys"
  cp "$AUTH_KEY_PATH" "$HOME/.private_keys/AuthKey_${TICH_APP_STORE_CONNECT_KEY_ID}.p8"
  chmod 0600 "$HOME/.private_keys/AuthKey_${TICH_APP_STORE_CONNECT_KEY_ID}.p8"
  PROFILE_DIRECTORY="$HOME/Library/MobileDevice/Provisioning Profiles"
  PROFILE_LIST="$RUNNER_TEMP/tich-installed-profiles.txt"
  mkdir -p "$PROFILE_DIRECTORY"
  : > "$PROFILE_LIST"

  install_tich_profile "$TICH_PROFILE_MAIN_BASE64" "$PROFILE_DIRECTORY" "$PROFILE_LIST"
  install_tich_profile "$TICH_PROFILE_NSE_BASE64" "$PROFILE_DIRECTORY" "$PROFILE_LIST"
  install_tich_profile "$TICH_PROFILE_SHARE_BASE64" "$PROFILE_DIRECTORY" "$PROFILE_LIST"

  security find-identity -v -p codesigning "$KEYCHAIN_PATH"
  export TICH_AUTH_KEY_PATH="$AUTH_KEY_PATH"
}

install_tich_profile() {
  PROFILE_BASE64="$1"
  PROFILE_DIRECTORY="$2"
  PROFILE_LIST="$3"
  PROFILE_TEMP="$(mktemp "$RUNNER_TEMP/tich-profile.XXXXXX")"
  printf '%s' "$PROFILE_BASE64" | base64 --decode > "$PROFILE_TEMP"
  PROFILE_UUID="$(security cms -D -i "$PROFILE_TEMP" | plutil -extract UUID raw -o - -)"
  PROFILE_TARGET="$PROFILE_DIRECTORY/$PROFILE_UUID.mobileprovision"
  mv "$PROFILE_TEMP" "$PROFILE_TARGET"
  chmod 0600 "$PROFILE_TARGET"
  printf '%s\n' "$PROFILE_TARGET" >> "$PROFILE_LIST"
}

cleanup_tich_signing() {
  security delete-keychain "$RUNNER_TEMP/tich-connect-signing.keychain-db" 2>/dev/null || true
  rm -f "$RUNNER_TEMP/tich-connect-distribution.p12" \
    "$RUNNER_TEMP/AuthKey_${TICH_APP_STORE_CONNECT_KEY_ID}.p8" \
    "$HOME/.private_keys/AuthKey_${TICH_APP_STORE_CONNECT_KEY_ID}.p8"
  if test -f "$RUNNER_TEMP/tich-installed-profiles.txt"; then
    while IFS= read -r profile; do
      rm -f "$profile"
    done < "$RUNNER_TEMP/tich-installed-profiles.txt"
    rm "$RUNNER_TEMP/tich-installed-profiles.txt"
  fi
}
