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

@MainActor
class ShopViewModel: ObservableObject {
    @Published var availableItems: [ShopItem] = []
    @Published var userPoints: Int = 0
    @Published var unlockedCustomizations: [String] = []
    
    @Published var isPurchasing: Bool = false
    @Published var errorMessage: String = ""
    
    private let dbRef = Database.database().reference()
    
    init() {
        Task {
            await fetchShopItems()
            await fetchUserData()
        }
    }
    
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
    
    func purchaseItem(item: ShopItem) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        guard !unlockedCustomizations.contains(item.id) else {
            errorMessage = "You already own this item!"
            return
        }
        guard userPoints >= item.cost else {
            errorMessage = "Not enough points!"
            return
        }
        
        isPurchasing = true
        errorMessage = ""
        
        do {
            let userRef = dbRef.child("users").child(userId)
            
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
