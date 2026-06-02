//
//  ShopViewModelTests.swift
//  LarvaTests
//
//  Created by student on 28/05/26.
//

import Testing
@testable import Larva

@Suite("Shop View Model Tests")
@MainActor
struct ShopViewModelTests {

    var viewModel: ShopViewModel

    init() {
        self.viewModel = ShopViewModel()
        
        self.viewModel.availableItems = [
            ShopItem(id: "theme_red", name: "Red Theme", description: "", cost: 500, itemType: .appTheme),
            ShopItem(id: "border_gold", name: "Gold Border", description: "", cost: 5000, itemType: .avatarBorder)
        ]
        self.viewModel.userPoints = 1000
        self.viewModel.unlockedCustomizations = ["pre_owned_item"]
    }

    @Test("Store items load successfully on initialization")
    func storeItemsLoad() {
        #expect(
            !viewModel.availableItems.isEmpty,
            "Store items should be populated in the test environment."
        )
        #expect(
            viewModel.availableItems.contains(where: { $0.id == "theme_red" }),
            "Should contain the mock shop items."
        )
    }

    @Test("Purchase fails and sets error if user is broke")
    func insufficientPointsPurchase() async {
        viewModel.userPoints = 100

        guard let expensiveItem = viewModel.availableItems.first(where: { $0.id == "border_gold" }) else {
            Issue.record("Could not find expensive test item.")
            return
        }

        await viewModel.purchaseItem(item: expensiveItem)

        #expect(
            viewModel.errorMessage == "Not enough points!",
            "Should trigger the insufficient points error."
        )
    }

    @Test("Purchase fails and sets error if item is already owned")
    func alreadyOwnedPurchase() async {
        let ownedItem = ShopItem(
            id: "pre_owned_item",
            name: "Pre-Owned",
            description: "",
            cost: 100,
            itemType: .appTheme
        )

        await viewModel.purchaseItem(item: ownedItem)

        #expect(
            viewModel.errorMessage == "You already own this item!",
            "Should trigger the already owned error."
        )
    }
}
