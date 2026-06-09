import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CatWindow!
    var viewModel: CatViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = CatViewModel()
        
        // Find visible screen frame
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
        
        let windowWidth: CGFloat = 150
        let windowHeight: CGFloat = 150
        
        // Start near the bottom right of the primary screen
        let initialRect = NSRect(
            x: screenFrame.maxX - windowWidth - 100,
            y: screenFrame.minY + 20, // Sit just above the Dock / screen bottom
            width: windowWidth,
            height: windowHeight
        )
        
        window = CatWindow(contentRect: initialRect, viewModel: viewModel)
        window.makeKeyAndOrderFront(nil)
        
        // Hiding or showing window across spaces
        window.orderFrontRegardless()
    }
}
