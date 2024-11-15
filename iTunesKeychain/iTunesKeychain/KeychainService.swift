//
//  KeychainService.swift
//  iTunesKeychain
//
//  Created by Ибрагим Габибли on 15.11.2024.
//

import Foundation
import KeychainSwift

class KeychainService {
    static let shared = KeychainService()
    private let keychain = KeychainSwift()
    private let historyKey = "searchHistory"

    private init() {}

    func saveAlbums(_ albums: [Album], for searchTerm: String) {
        do {
            let data = try JSONEncoder().encode(albums)
            keychain.set(data, forKey: searchTerm)
        } catch {
            print("Failed to encode characters: \(error)")
        }
    }

    func saveImage(_ image: Data, key: String) {
        keychain.set(image, forKey: key)
    }

    func saveSearchTerm(_ term: String) {
        var history = getSearchHistory()
        if !history.contains(term) {
            history.append(term)
            if let data = try? JSONEncoder().encode(history) {
                keychain.set(data, forKey: historyKey)
            }
        }
    }

    func loadAlbums(for searchTerm: String) -> [Album]? {
        guard let data = keychain.getData(searchTerm) else {
            return nil
        }

        do {
            let albums = try JSONDecoder().decode([Album].self, from: data)
            return albums
        } catch {
            print("Failed to decode: \(error)")
            return nil
        }
    }

    func loadImage(key: String) -> Data? {
        return keychain.getData(key)
    }

    func getSearchHistory() -> [String] {
        guard let data = keychain.getData(historyKey) else {
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
            keychain.delete(term)
        }
        clearHistory()
    }

    func clearImage(key: String) {
        keychain.delete(key)
    }

    func clearHistory() {
        keychain.delete(historyKey)
    }
}
