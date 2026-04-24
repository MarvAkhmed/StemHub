//
//  SecTaskEntitlementInspector.swift
//  StemHub_macOS
//
//  Created by Marwa Awad on 24.04.2026.
//

import Foundation

#if os(macOS)
import Security
#endif

protocol AppEntitlementInspecting {
    func stringArrayValue(for entitlement: String) -> [String]?
}

#if os(macOS)
struct SecTaskEntitlementInspector: AppEntitlementInspecting {
    func stringArrayValue(for entitlement: String) -> [String]? {
        guard let task = SecTaskCreateFromSelf(nil) else {
            return nil
        }

        let entitlementKey = entitlement as NSString
        return SecTaskCopyValueForEntitlement(task, entitlementKey, nil) as? [String]
    }
}
#else
struct SecTaskEntitlementInspector: AppEntitlementInspecting {
    func stringArrayValue(for entitlement: String) -> [String]? {
        nil
    }
}
#endif
