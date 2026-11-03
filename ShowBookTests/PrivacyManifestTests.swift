//
//  PrivacyManifestTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 03/11/26.
//

import XCTest
@testable import ShowBook

final class PrivacyManifestTests: XCTestCase {

    private func loadPrivacyManifest() throws -> [String: Any] {
        let manifestURL = Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
            ?? Bundle(for: Self.self).url(forResource: "PrivacyInfo", withExtension: "xcprivacy")

        guard let url = manifestURL else {
            XCTFail("PrivacyInfo.xcprivacy not found in test or main bundle")
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            XCTFail("Failed to parse PrivacyInfo.xcprivacy as property list dictionary")
            throw CocoaError(.fileReadCorruptFile)
        }
        return plist
    }

    func testPrivacyManifestStructureAndTracking() throws {
        let manifest = try loadPrivacyManifest()

        // 1. Zero tracking compliance
        let tracking = manifest["NSPrivacyTracking"] as? Bool
        XCTAssertEqual(tracking, false, "ShowBook must declare NSPrivacyTracking as false")

        let domains = manifest["NSPrivacyTrackingDomains"] as? [String]
        XCTAssertEqual(domains, [], "ShowBook must have empty NSPrivacyTrackingDomains")
    }

    func testRequiredReasonAPIsDeclared() throws {
        let manifest = try loadPrivacyManifest()

        guard let accessedAPITypes = manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]] else {
            XCTFail("NSPrivacyAccessedAPITypes must be an array of dictionaries")
            return
        }

        let userDefaultsDeclaration = accessedAPITypes.first { dict in
            (dict["NSPrivacyAccessedAPIType"] as? String) == "NSPrivacyAccessedAPICategoryUserDefaults"
        }
        XCTAssertNotNil(userDefaultsDeclaration, "UserDefaults required-reason API must be declared")

        let reasons = userDefaultsDeclaration?["NSPrivacyAccessedAPITypeReasons"] as? [String]
        XCTAssertTrue(reasons?.contains("CA92.1") == true, "UserDefaults API reason must declare CA92.1")
    }

    func testCollectedDataTypesDeclared() throws {
        let manifest = try loadPrivacyManifest()

        guard let collectedTypes = manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]] else {
            XCTFail("NSPrivacyCollectedDataTypes must be an array of dictionaries")
            return
        }

        let declaredTypes = Set(collectedTypes.compactMap { $0["NSPrivacyCollectedDataType"] as? String })
        let expectedTypes: Set<String> = [
            "NSPrivacyCollectedDataTypeUserID",
            "NSPrivacyCollectedDataTypeEmailAddress",
            "NSPrivacyCollectedDataTypeOtherUserContent"
        ]

        XCTAssertTrue(expectedTypes.isSubset(of: declaredTypes), "Missing expected data types in privacy manifest")

        for entry in collectedTypes {
            let isTracking = entry["NSPrivacyCollectedDataTypeTracking"] as? Bool
            XCTAssertEqual(isTracking, false, "Collected data must not be used for tracking")

            let purposes = entry["NSPrivacyCollectedDataTypePurposes"] as? [String]
            XCTAssertTrue(
                purposes?.contains("NSPrivacyCollectedDataTypePurposeAppFunctionality") == true,
                "Purpose must be App Functionality"
            )
        }
    }

    func testPrivacyPolicyAndSupportURLsAreReachable() {
        let policyURL = URL(string: "https://github.com/Anurag-Chourasia/ShowBook/blob/main/Docs/PrivacyInventory.md")
        XCTAssertNotNil(policyURL)
        XCTAssertEqual(policyURL?.scheme, "https")

        let supportURL = URL(string: "mailto:anuragchourasiaios@gmail.com")
        XCTAssertNotNil(supportURL)
        XCTAssertEqual(supportURL?.scheme, "mailto")
    }
}
