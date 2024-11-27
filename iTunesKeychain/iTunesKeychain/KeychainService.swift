//
//  KeychainService.swift
//  iTunesKeychain
//
//  Created by Ибрагим Габибли on 15.11.2024.
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let historyKey = "searchHistory"
    private let queue = DispatchQueue(label: "KeychainServiceQueue")

    private init() {}

    func saveAlbums(_ albums: [Album], for searchTerm: String) {
        do {
            let data = try JSONEncoder().encode(albums)
            let status = save(data, forKey: searchTerm)
            if status != errSecSuccess {
                print("Failed to save albums to keychain. Error code: \(status)")
            }
        } catch {
            print("Failed to encode albums: \(error.localizedDescription)")
        }
    }

    func saveImage(_ data: Data, key: String) {
        let status = save(data, forKey: key)
        if status != errSecSuccess {
            print("Failed to save image to keychain. Error code: \(status)")
        }
    }

    func saveSearchTerm(_ term: String) {
        var history = getSearchHistory()
        if !history.contains(term) {
            history.append(term)
            do {
                let data = try JSONEncoder().encode(history)
                let status = save(data, forKey: historyKey)
                if status != errSecSuccess {
                    print("Failed to save search history to keychain. Error code: \(status)")
                }
            } catch {
                print("Failed to encode search history: \(error.localizedDescription)")
            }
        }
    }

    func loadAlbums(for searchTerm: String) -> [Album]? {
        guard let data = load(forKey: searchTerm) else {
            return nil
        }

        do {
            let albums = try JSONDecoder().decode([Album].self, from: data)
            return albums
        } catch {
            print("Failed to decode albums: \(error.localizedDescription)")
            return nil
        }
    }

    func loadImage(key: String) -> Data? {
        return load(forKey: key)
    }

    func getSearchHistory() -> [String] {
        guard let data = load(forKey: historyKey) else {
            return []
        }

        do {
            let history = try JSONDecoder().decode([String].self, from: data)
            return history
        } catch {
            print("Failed to decode history: \(error)")
            return []
        }
    }

    func clearAlbums() {
        let history = getSearchHistory()
        for term in history {
            delete(forKey: term)
        }
        clearHistory()
    }

    func clearImage(key: String) {
        delete(forKey: key)
    }

    func clearHistory() {
        delete(forKey: historyKey)
    }
}

// MARK: - Helper methods for Keychain management
extension KeychainService {
    private func save(_ data: Data, forKey key: String) -> OSStatus {
        return queue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]

            SecItemDelete(query as CFDictionary)

            return SecItemAdd(query as CFDictionary, nil)
        }
    }

    private func load(forKey key: String) -> Data? {
        return queue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess {
                return result as? Data
            } else {
                print("Failed to load data for key \(key). Status: \(status)")
                return nil
            }
        }
    }

    private func delete(forKey key: String) {
        queue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]

            let status = SecItemDelete(query as CFDictionary)

            if status != errSecSuccess && status != errSecItemNotFound {
                print("Failed to delete data for key \(key). Error code: \(status)")
            }
        }
    }
}
