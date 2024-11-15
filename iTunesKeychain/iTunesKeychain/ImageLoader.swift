//
//  ImageLoader.swift
//  iTunesKeychain
//
//  Created by Ибрагим Габибли on 15.11.2024.
//

import Foundation
import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private init() {}

    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {

        if let imageData = KeychainService.shared.loadImage(key: urlString),
           let image = UIImage(data: imageData) {
            completion(image)
            return
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let data,
               let image = UIImage(data: data) {
                KeychainService.shared.saveImage(data, key: urlString)
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
