//
//  ShopItem.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation

struct ShopItem: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var cost: Int
    var itemType: ItemType
    
    enum ItemType: String, Codable {
        case mapTheme, avatarBorder, appIcon
    }
}
