//
//  WorkoutStat.swift
//  Larva
//
//  Created by Elifele Fredrik on 11/06/26.
//

import SwiftUI

struct WorkoutStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(color).font(.caption)
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            Text(value).font(.headline).fontWeight(.bold)
        }
    }
}
