//
//  ModelSetupView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

struct ModelSetupView: View {
    var body: some View {
        VStack {
            Text("Pepare your model for inspection")
            // Add your model preparation UI here
            NavigationLink(destination: InspectionView()) {
                Text("Go to Inspection View")
            }
        }
        .navigationTitle("Model Setup View")
    }
}
