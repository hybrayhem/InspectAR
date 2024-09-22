//
//  InspectionView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

struct InspectionView: View {
    var body: some View {
        VStack {
            Text("Inspect Model")
            // Add your model inspection UI here
        }
        .navigationTitle("Inspect Model")
        .onAppear {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
    }
}
