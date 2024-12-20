//
//  KeychainManager.swift
//  qrcode2
//
//  Created by Emil V Rainero on 12/18/24.
//

import Foundation
import Security

let tokenKey = "authToken"

class KeychainManager {
    static let shared = KeychainManager()

    private init() {} // Singleton instance

    /// Saves a token to the Keychain
    @discardableResult
    func save(token: String, forKey key: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else { return false }

        // Create a query to store the token
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: tokenData
        ]

        // Remove any existing item with the same key
        SecItemDelete(query as CFDictionary)

        // Add the new token to the Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieves a token from the Keychain
    func retrieveToken(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let tokenData = item as? Data {
            return String(data: tokenData, encoding: .utf8)
        }
        return nil
    }

    /// Deletes a token from the Keychain
    @discardableResult
    func deleteToken(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}


/*
 let tokenKey = "authToken"

// Save a token
let saveSuccess = KeychainManager.shared.save(token: "mySecureToken123", forKey: tokenKey)
print("Token saved: \(saveSuccess)")

// Retrieve the token
if let retrievedToken = KeychainManager.shared.retrieveToken(forKey: tokenKey) {
    print("Retrieved token: \(retrievedToken)")
} else {
    print("Failed to retrieve token")
}

// Delete the token
let deleteSuccess = KeychainManager.shared.deleteToken(forKey: tokenKey)
print("Token deleted: \(deleteSuccess)")
*/
