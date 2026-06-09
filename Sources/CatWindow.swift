import AppKit
import SwiftUI

class CatWindow: NSPanel {
    init(contentRect: NSRect, viewModel: CatViewModel) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = true
        self.backgroundColor = .clear
        self.hasShadow = false
        
        // Floating on top of other windows
        self.level = .floating
        
        // Show on all virtual desktops (Spaces)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Host SwiftUI view inside the draggable hosting view
        let catView = CatView(viewModel: viewModel)
        let hostingView = DraggableHostingView(rootView: catView, viewModel: viewModel)
        self.contentView = hostingView
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
