//
//  QuestRow.swift
//  Larva
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct QuestRow: View {
    let quest: Quest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(quest.title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(quest.rewardPoints)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(quest.isCompleted ? Color.mint : Color.orange)
                        .frame(width: min(CGFloat(quest.currentProgress) / CGFloat(quest.targetGoal) * geometry.size.width, geometry.size.width), height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(quest.currentProgress) / \(quest.targetGoal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if quest.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.mint)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
