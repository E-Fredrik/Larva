//
//  DailyStepsCard.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

struct DailyStepsCard: View {
    let stepCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("DAILY TARGET PROGRESS")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(stepCount)")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.heavy)
                    Text("steps")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            Image(systemName: "flame.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.orange)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

#Preview {
    DailyStepsCard(stepCount: 4500)
}
