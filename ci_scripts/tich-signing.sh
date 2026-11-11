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
  mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"

  security find-identity -v -p codesigning "$KEYCHAIN_PATH"
  export TICH_AUTH_KEY_PATH="$AUTH_KEY_PATH"
}

cleanup_tich_signing() {
  security delete-keychain "$RUNNER_TEMP/tich-connect-signing.keychain-db" 2>/dev/null || true
  rm -f "$RUNNER_TEMP/tich-connect-distribution.p12" \
    "$RUNNER_TEMP/AuthKey_${TICH_APP_STORE_CONNECT_KEY_ID}.p8" \
    "$HOME/.private_keys/AuthKey_${TICH_APP_STORE_CONNECT_KEY_ID}.p8"
}
