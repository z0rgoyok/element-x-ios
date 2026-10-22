//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct AppSettingsTests {
    @Test
    func defaultAccountProvider() {
        let appSettings = AppSettings.volatile()
        appSettings.override(allowOtherAccountProviders: true)
        #expect(appSettings.defaultAccountProvider == appSettings.accountProviders[0])
        
        appSettings.previousServers = ["example.com"]
        #expect(appSettings.defaultAccountProvider == .generic("example.com"))
        
        appSettings.override(allowOtherAccountProviders: false)
        #expect(appSettings.defaultAccountProvider == appSettings.accountProviders[0])
    }
    
    @Test
    func tichAccountProviderRemainsPinned() {
        let appSettings = AppSettings.volatile()
        appSettings.previousServers = ["example.com"]
        #expect(appSettings.defaultAccountProvider == .managed(serverName: "connect.tich.app", baseURL: "https://connect.tich.app"))
        #expect(!appSettings.allowOtherAccountProviders)
        #expect(!appSettings.showCreateAccountButton)
    }
}

// MARK: - Helpers

extension AppSettings {
    func override(allowOtherAccountProviders: Bool) {
        override(accountProviders: accountProviders,
                 allowOtherAccountProviders: allowOtherAccountProviders,
                 hideBrandChrome: hideBrandChrome,
                 pushGatewayBaseURL: pushGatewayBaseURL,
                 oAuthRedirectURL: oAuthRedirectURL,
                 oAuthClientURIPath: oAuthClientURIPath,
                 websiteURL: websiteURL,
                 logoURL: logoURL,
                 copyrightURL: copyrightURL,
                 acceptableUseURL: acceptableUseURL,
                 privacyURL: privacyURL,
                 encryptionURL: encryptionURL,
                 deviceVerificationURL: deviceVerificationURL,
                 chatBackupDetailsURL: chatBackupDetailsURL,
                 identityPinningViolationDetailsURL: identityPinningViolationDetailsURL,
                 historySharingDetailsURL: historySharingDetailsURL,
                 elementWebHosts: elementWebHosts,
                 accountProvisioningHost: accountProvisioningHost,
                 bugReportApplicationID: bugReportApplicationID,
                 analyticsTermsURL: analyticsTermsURL,
                 mapTilerConfiguration: mapTilerConfiguration.publisher.value)
    }
}
