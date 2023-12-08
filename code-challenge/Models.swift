//
//  Models.swift
//  code-challenge
//

import Foundation

let firstEndpoint = "https://sc.cnbc.com/applications/mobileapps/ios/stage/first/items.json"
let secondEndpoint = "https://sc.cnbc.com/applications/mobileapps/ios/stage/second/items.json"

struct Feed: Codable {
    let models: [Model]
}

struct Model: Codable, Hashable {
    let id: Int
    let position: Int
    let text: String
    let thumbnailURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "i_d"
        case position = "po_si_tion"
        case text = "te_xt"
        case thumbnailURL = "thumbnail_URL"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = Int(try values.decode(String.self, forKey: .id)) ?? 0
        self.position = try values.decode(Int.self, forKey: .position)
        self.text = try values.decode(String.self, forKey: .text)
        self.thumbnailURL = try values.decodeIfPresent(String.self, forKey: .thumbnailURL)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(String(id), forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
    }
}
