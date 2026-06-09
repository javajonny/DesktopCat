import AppKit
import SwiftUI

class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var initialLocation: NSPoint?
    private let viewModel: CatViewModel

    init(rootView: Content, viewModel: CatViewModel) {
        self.viewModel = viewModel
        super.init(rootView: rootView)
    }

    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor @preconcurrency required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        viewModel.startDragging()
        initialLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window, let initialLocation = initialLocation else { return }
        
        // Get mouse position on screen
        let mouseLocation = NSEvent.mouseLocation
        
        // Calculate new origin so the cursor stays exactly at the same relative position on the cat
        let newOrigin = NSPoint(
            x: mouseLocation.x - initialLocation.x,
            y: mouseLocation.y - initialLocation.y
        )
        
        window.setFrameOrigin(newOrigin)
        
        // Calculate drag tilt based on mouse velocity deltaX
        let deltaX = event.deltaX
        viewModel.updateDragVelocity(deltaX: deltaX)
    }

    override func mouseUp(with event: NSEvent) {
        viewModel.stopDragging()
        initialLocation = nil
    }
}
