//
//  ShopItem.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import Foundation

/// A purchasable cosmetic item available in the in-app shop.
/// Items are stored in Firebase under `shopItems/<id>` and fetched by `ShopViewModel`.
struct ShopItem: Identifiable, Codable {
    /// Unique identifier matching the Firebase node key for this item.
    var id: String
    /// Display name shown in the shop and inventory (e.g. "Ocean Theme").
    var name: String
    /// Short explanation of what the item does, shown in the shop card.
    var description: String
    /// Point cost the user must spend to unlock this item.
    var cost: Int
    /// Determines which slot the item occupies and how it is applied to the UI.
    var itemType: ItemType
    /// Optional hex colour string (e.g. "#00C8B4") used to tint the app or avatar border
    /// when this item is equipped. `nil` means no colour tint is applied.
    var colorHex: String?

    /// Categories of cosmetic item available in the shop.
    enum ItemType: String, Codable, CaseIterable {
        /// Changes the app's primary accent colour (tint) throughout all views.
        case appTheme = "appTheme"
        /// Applies a coloured ring around the user's avatar circle.
        case avatarBorder = "avatarBorder"
    }
}
