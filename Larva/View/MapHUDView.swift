//
//  SwiftUIView.swift
//  LarvaLawas
//
//  Created by Eko Nur Cahyo S on 27/05/26.
//

import SwiftUI
import MapKit

struct MapHUDView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            // Map Initialization
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true)
                .ignoresSafeArea()
                .tint(.mint)
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Steps: 4")
                            .font(.headline)
                        Text("Distance: 20m")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(16)
                .padding()
                
                Spacer()
            }
        }
    }
}
struct MapHUDView_Previews: PreviewProvider {
    static var previews: some View {
        MapHUDView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
            .preferredColorScheme(.dark)
    }
}
