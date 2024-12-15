//
//  RootView.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

struct RootView : View {
    var body: some View {
        NavigationStack {
            ModelGalleryView()
        }
        // .rotationEffect(.degrees(180))
    }
}

#Preview {
    RootView()
}
