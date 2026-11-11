#!/bin/sh

# Return on failures
# Fail when expanding unset variables
# Trace each command before executing it
set -eEu

install_xcode_cloud_brew_dependencies () {
    brew update && brew install xcodegen pkl getsentry/tools/sentry-cli
}

setup_github_actions_environment() {
    xcode_select_for_github_actions
    
    unset HOMEBREW_NO_INSTALL_FROM_API
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
    
    brew update && brew install xcodegen swiftlint git-lfs pkl
    install_pinned_swiftformat
}

install_pinned_swiftformat() {
    SWIFTFORMAT_VERSION="0.64.0"
    SWIFTFORMAT_SHA256="95ea62625d0b898a7af870293311ae6f09e4a3147ecd900593687e4b9ab2fd98"
    SWIFTFORMAT_DIR="$(mktemp -d)"
    curl --fail --silent --show-error --location \
        "https://github.com/nicklockwood/SwiftFormat/releases/download/${SWIFTFORMAT_VERSION}/swiftformat.zip" \
        --output "${SWIFTFORMAT_DIR}/swiftformat.zip"
    printf '%s  %s\n' "$SWIFTFORMAT_SHA256" "${SWIFTFORMAT_DIR}/swiftformat.zip" | shasum -a 256 -c -
    unzip -q "${SWIFTFORMAT_DIR}/swiftformat.zip" -d "$SWIFTFORMAT_DIR"
    sudo install -m 0755 "${SWIFTFORMAT_DIR}/swiftformat" /usr/local/bin/swiftformat
    /usr/local/bin/swiftformat --version | grep -Fx "$SWIFTFORMAT_VERSION"
    rm "${SWIFTFORMAT_DIR}/swiftformat" "${SWIFTFORMAT_DIR}/swiftformat.zip"
    rmdir "$SWIFTFORMAT_DIR"
}


setup_github_actions_translations_environment() {
    xcode_select_for_github_actions
    
    unset HOMEBREW_NO_INSTALL_FROM_API
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

    brew update && brew install swiftgen mint localazy/tools/localazy

    mint install Asana/locheck
}

xcode_select_for_github_actions() {
    # We need to select it globally for our custom tools to use the same Xcode version.
    sudo xcode-select -s /Applications/Xcode_27.app
}

generate_what_to_test_notes() {
    if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
        TESTFLIGHT_DIR_PATH=TestFlight
        TESTFLIGHT_NOTES_FILE_NAME=WhatToTest.en-US.txt
        
        LATEST_TAG=""
        if [ "$CI_WORKFLOW" = "Release" ]; then
            # Use -v to invert grep, searching for non-nightlies
            LATEST_TAG=$(git tag --sort=-creatordate | grep -v 'nightly' | head -n1)
        elif [ "$CI_WORKFLOW" = "Nightly" ]; then
            LATEST_TAG=$(git tag --sort=-creatordate | grep 'nightly' | head -n1)
        fi

        if [[ -z "$LATEST_TAG" ]]; then
            echo "generate_what_to_test_notes: Failed fetching previous tag"
            return 0 # Continue even though this failed
        fi

        echo "generate_what_to_test_notes: latest tag is $LATEST_TAG"

        mkdir $TESTFLIGHT_DIR_PATH

        NOTES="$(git log --pretty='- %an: %s' "$LATEST_TAG"..HEAD)"

        echo "generate_what_to_test_notes: Generated notes:\n"$NOTES""

        echo "$NOTES" > $TESTFLIGHT_DIR_PATH/$TESTFLIGHT_NOTES_FILE_NAME
    fi
}

fetch_unshallow_repository() {
    # Xcode Cloud shallow clones the repo. We need to deepen it to fetch tags, commit history and be able to rebase main on develop at the end of releases.
    git fetch --unshallow --quiet
}
