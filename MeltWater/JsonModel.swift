//
//  JsonModel.swift
//  MeltWater
//
//  Created by Arfhan Ahmad on 8/10/18.
//  Copyright © 2018 Arfhan Ahmad. All rights reserved.
//

import Foundation

struct JsonModel : Codable {
    let id : String?
    let description : String?
    let comments: Int?
    let created_at : String?
    let owner : Owner? // Parse nested object key
    let files: File? // Parse nested object key
    
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        comments = try values.decodeIfPresent(Int.self, forKey: .comments)
        created_at = try values.decodeIfPresent(String.self, forKey: .created_at)
        owner = try values.decodeIfPresent(Owner.self, forKey: .owner)
        files = try values.decodeIfPresent(File.self, forKey: .files)
    }
}

struct Owner : Codable {
    let login : String?
    let avatar_url: String?
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        login = try values.decodeIfPresent(String.self, forKey: .login)
        avatar_url = try values.decodeIfPresent(String.self, forKey: .avatar_url)
    }
}

private struct CustomCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}

struct File : Codable {
    let filename : String?
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CustomCodingKeys.self)
        self.filename = values.allKeys[0].stringValue // Getting first object key name for first file
    }
}

