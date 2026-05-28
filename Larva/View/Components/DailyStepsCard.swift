//
//  DailyStepsCard.swift
//  Larva
//
//  Created by Elifele Fredrik on 28/05/26.
//

import SwiftUI

struct DailyStepsCard: View {
    let stepCount: Int
        let targetSteps: Int
        
        var progress: Double {
            Double(stepCount) / Double(targetSteps)
        }
        
        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    ActivityRing(progress: progress, color: .mint)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "figure.walk")
                        .foregroundColor(.mint)
                        .font(.system(size: 20, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAILY TARGET")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(stepCount)")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                        
                        Text("/ \(targetSteps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(20)
        }
}

#Preview {
    DailyStepsCard(stepCount: 4500, targetSteps: 5000)
}
