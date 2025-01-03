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
//#if !targetEnvironment(simulator)
//        .rotationEffect(.degrees(180))
//#endif
    }
}

#Preview {
    RootView()
}
