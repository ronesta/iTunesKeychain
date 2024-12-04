//
//  KeychainService.swift
//  iTunesKeychain
//
//  Created by Ибрагим Габибли on 15.11.2024.
//

import Foundation
import Security

final class KeychainSevice {
    static let shared = KeychainSevice()

    private let queue = DispatchQueue(label: "KeychainServiceQueue")
    private let historyKey = "searchHistory"

    private init() {}

    func saveAlbum(_ album: Album, for searchTerm: String) {
        let key = "\(searchTerm)-\(album.artistId)"

        do {
            let data = try JSONEncoder().encode(album)
            let status = save(data, forKey: key)

            if status != errSecSuccess {
                print("Failed to save albums to keychain. Error code: \(status)")
            }
        } catch {
            print("Failed to encode album: \(error.localizedDescription)")
        }
    }

    func loadAlbums(for searchTerm: String) -> [Album] {
        var albums = [Album]()

        guard let keys = getAllKeys() else {
            return []
        }
        let relevantKeys = keys.filter { $0.hasPrefix("\(searchTerm)-") }

        for key in relevantKeys {
            if let data = load(forKey: key) {
                do {
                    let album = try JSONDecoder().decode(Album.self, from: data)
                    albums.append(album)
                } catch {
                    print("Failed to decode album: \(error.localizedDescription)")
                }
            }
        }

        return albums
    }

    func saveImage(_ image: Data, key: String) {
        let status = save(image, forKey: key)

        if status != errSecSuccess {
            print("Failed to save image to keychain. Error code: \(status)")
        }
    }

    func loadImage(key: String) -> Data? {
        return load(forKey: key)
    }

    func saveSearchTerm(_ term: String) {
        var history = getSearchHistory()

        guard !history.contains(term) else {
            return
        }

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

    func getSearchHistory() -> [String] {
        guard let data = load(forKey: historyKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Error decoding search history: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Keychain Helper Methods
extension KeychainSevice {
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
            guard exists(forKey: key) else {
                return nil
            }

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

    private func getAllKeys() -> [String]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            print("Failed to retrieve keys from Keychain: \(status)")
            return nil
        }

        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }

    private func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        return status == errSecSuccess
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
