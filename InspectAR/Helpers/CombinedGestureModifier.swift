//
//  CombinedGestureModifier.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

enum GestureType {
    case tap
    case drag
    case magnification
    // case longPress
}

enum CombinationType {
    case simultaneous
    case exclusive
}


//struct GestureCombiner<T: Gesture, K: Gesture> {
//    let first: T
//    let second: K
//
//    func combinedGesture() -> some Gesture {
//        first.simultaneously(with: second)
//    }
//}

struct CombinedGestureModifier: ViewModifier {
    let gestures: [GestureType]
    let combination: CombinationType
    let action: () -> Void

    func body(content: Content) -> some View {
//        var combinedGesture: some Gesture {
////            gestures.reduce(AnyGesture(TapGesture().onEnded { action() })) { combined, gestureType in
////                switch gestureType {
////                case .tap:
////                    let newGesture = TapGesture().onEnded { action() }
////                    return GestureCombiner(first: combined, second: newGesture).combinedGesture()
////                case .drag:
////                    let newGesture = DragGesture().onChanged { _ in action() }
////                    return GestureCombiner(first: combined, second: newGesture).combinedGesture()
////                case .magnification:
////                    let newGesture = MagnificationGesture().onChanged { _ in action() }
////                    return GestureCombiner(first: combined, second: newGesture).combinedGesture()
////                }
////            }
//            let combined = TapGesture().onEnded { action() }
//            let newGesture = DragGesture().onChanged { _ in action() }
//            return GestureCombiner(first: combined, second: newGesture).combinedGesture()
//        }
        var combinedGesture: AnyGesture<Any>
        
        // First gesture
        var initialGesture: AnyGesture<Void>? = nil

        for gesture in gestures {
            switch gesture {
            case .tap:
                initialGesture = AnyGesture(TapGesture().onEnded { _ in action() })
            case .drag:
                initialGesture = AnyGesture(DragGesture().onChanged { _ in action() }.onEnded { _ in action() })
            case .magnification:
                initialGesture = AnyGesture(MagnificationGesture().onChanged { _ in action() }.onEnded { _ in action() })
            }
        }

        if let gesture = initialGesture {
            return content.gesture(gesture)
        } else {
            return content
        }
        
        // All other gestures
        
        return content.gesture(combinedGesture)
    }
}


//struct CombinedGestureModifier: ViewModifier {
//    let gestures: [GestureType]
//    let combinationType: CombinationType
//    let action: () -> Void
//
//    func body(content: Content) -> some View {
//        guard let firstGestureType = gestures.first else {
//            return content
//        }
//
//        func gesture(for type: GestureType) -> AnyGesture<()> {
//            switch type {
//            case .tap:
//                return AnyGesture(TapGesture().onEnded { action() })
//            case .drag:
//                return AnyGesture(DragGesture().onChanged { _ in action() })
//            case .magnification:
//                return AnyGesture(MagnificationGesture().onChanged { _ in action() })
//            }
//        }
//
//        let initialGesture = gesture(for: firstGestureType)
//
//        let combinedGesture = gestures.dropFirst().reduce(initialGesture) { combined, gestureType in
//            let newGesture = gesture(for: gestureType)
//            return combined.simultaneously(with: newGesture) // combineGestures(combined, newGesture)
//        }
//
//        return content.gesture(combinedGesture)
//    }
//    
//    private func combineGestures<T: Gesture>(_ first: T, _ second: T) -> any Gesture {
//        switch combinationType {
//        case .simultaneous:
//            return first.simultaneously(with: second)
//        case .exclusive:
//            return first.exclusively(before: second)
//        }
//    }
//}
//
//extension View {
//    func combinedGestures(_ gestures: [GestureType], combinationType: CombinationType, action: @escaping () -> Void) -> some View {
//        self.modifier(CombinedGestureModifier(gestures: gestures, combinationType: combinationType, action: action))
//    }
//}
