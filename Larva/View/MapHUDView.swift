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
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: locationManager.waypoints) { waypoint in
                MapAnnotation(coordinate: waypoint.coordinate) {
                    if !waypoint.isClaimed {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(Color.mint.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .fill(Color.mint)
                                    .frame(width: 16, height: 16)
                                    .shadow(radius: 3)
                            }
                            Text(waypoint.name)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(4)
                                .background(.thinMaterial)
                                .cornerRadius(8)
                        }
                    }
                }
            }
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
