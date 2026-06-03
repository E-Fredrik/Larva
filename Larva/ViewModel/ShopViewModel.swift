//
//  ShopViewModel.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import Combine

/// Handles fetching the shop item catalogue from Firebase, reading the user's
/// current point balance, and processing item purchases.
@MainActor
class ShopViewModel: ObservableObject {
    /// All shop items available for purchase, fetched from `shopItems` in Firebase.
    @Published var availableItems: [ShopItem] = []
    /// The current user's point balance, kept in sync via a Firebase listener.
    @Published var userPoints: Int = 0
    /// IDs of items the user already owns (used to show "Owned" badge in the shop).
    @Published var unlockedCustomizations: [String] = []
    
    /// `true` while a purchase transaction is in-flight (prevents duplicate taps).
    @Published var isPurchasing: Bool = false
    /// Set to a human-readable string if a purchase fails; displayed below the shop grid.
    @Published var errorMessage: String = ""
    
    private let dbRef = Database.database(url: "https://larvva-d2753-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    
    init() {
        Task {
            await fetchShopItems()
            await fetchUserData()
        }
    }
    
    /// Fetches all documents from the `shopItems` Firebase node and decodes them into
    /// `ShopItem` objects. Replaces the entire `availableItems` array on success.
    func fetchShopItems() async {
        do {
            let snapshot = try await dbRef.child("shopItems").getData()
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else { return }
            
            var items: [ShopItem] = []
            for child in children {
                if let dict = child.value as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                   let item = try? JSONDecoder().decode(ShopItem.self, from: jsonData) {
                    items.append(item)
                }
            }
            self.availableItems = items
        } catch {
            print("Error fetching shop items: \(error.localizedDescription)")
        }
    }
    
    /// Attaches a persistent Firebase listener to the current user's node to keep
    /// `userPoints` and `unlockedCustomizations` up-to-date in real time.
    func fetchUserData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        dbRef.child("users").child(userId).observe(.value) { snapshot in
            if let dict = snapshot.value as? [String: Any] {
                self.userPoints = dict["points"] as? Int ?? 0
                
                if let unlocked = dict["unlockedCustomizations"] as? [String] {
                    self.unlockedCustomizations = unlocked
                }
            }
        }
    }
    
    /// Attempts to purchase `item` for the current user.
    ///
    /// Validates that the user doesn't already own the item and has enough points,
    /// then atomically deducts `item.cost` from the user's point balance and appends
    /// `item.id` to their `unlockedCustomizations` list in Firebase.
    func purchaseItem(item: ShopItem) async {
        guard !unlockedCustomizations.contains(item.id) else {
            errorMessage = "You already own this item!"
            return
        }
        guard userPoints >= item.cost else {
            errorMessage = "Not enough points!"
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication error. Please log in again."
            return
        }
        
        isPurchasing = true
        errorMessage = ""
        
        do {
            let userRef = dbRef.child("users").child(userId)
            
            // Atomically decrement the user's point balance.
            try await userRef.child("points").setValue(ServerValue.increment(NSNumber(value: -item.cost)))
            
            var updatedCustomizations = self.unlockedCustomizations
            updatedCustomizations.append(item.id)
            try await userRef.child("unlockedCustomizations").setValue(updatedCustomizations)
            
            print("Successfully purchased \(item.name)")
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        
        isPurchasing = false
    }
}
