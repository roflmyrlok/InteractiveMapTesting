//
//  KeyboardDismissManager.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 10.04.2025.
//

import SwiftUI
import UIKit

// Custom gesture recognizer that detects touches outside of text fields
class AnyGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touchedView = touches.first?.view, touchedView is UIControl {
            state = .cancelled
        } else if let touchedView = touches.first?.view as? UITextView, touchedView.isEditable {
            state = .cancelled
        } else {
            state = .began
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}

// UIViewControllerRepresentable to add the gesture recognizer to the window
struct KeyboardDismissGestureRepresentable: UIViewControllerRepresentable {
    class KeyboardDismissViewController: UIViewController, UIGestureRecognizerDelegate {
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Get the window from the view's window scene
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            // Add gesture recognizer to the window
            let tapGesture = AnyGestureRecognizer(target: window, action: #selector(UIView.endEditing))
            tapGesture.requiresExclusiveTouchType = false
            tapGesture.cancelsTouchesInView = false
            tapGesture.delegate = self
            window.addGestureRecognizer(tapGesture)
        }
        
        // UIGestureRecognizerDelegate method
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
    
    func makeUIViewController(context: Context) -> KeyboardDismissViewController {
        return KeyboardDismissViewController()
    }
    
    func updateUIViewController(_ uiViewController: KeyboardDismissViewController, context: Context) {}
}

// View modifier to add keyboard dismissal functionality
struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KeyboardDismissGestureRepresentable())
    }
}

// Extension to make it easy to use in SwiftUI views
extension View {
    func dismissKeyboardOnTapOutside() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
}
