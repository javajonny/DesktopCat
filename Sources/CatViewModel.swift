import Foundation
import Combine
import AppKit
import SwiftUI

enum CatState: String {
    case sleeping
    case awake
    case dragging
}

class CatViewModel: ObservableObject {
    @Published var state: CatState = .awake
    @Published var dragTilt: CGFloat = 0.0
    @Published var eyeClosedRatio: CGFloat = 0.0
    @Published var legsTwitch: Bool = false
    @Published var zzzList: [ZZZItem] = []
    @Published var isFacingLeft: Bool = false

    // Walking sub-state and leg animation phase
    @Published var isWalking: Bool = false
    @Published var walkLegPhase: CGFloat = 0.0

    struct ZZZItem: Identifiable {
        let id = UUID()
        var offset: CGSize
        var opacity: Double
        var scale: CGFloat
    }

    private var zzzTimer: Timer?
    private var blinkTimer: Timer?
    private var activityTimer: Timer?
    private var walkingTimer: Timer?

    init() {
        startBlinkTimer()
        startActivityTimer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkGravity()
        }
    }

    // MARK: - Drag

    func startDragging() {
        state = .dragging
        dragTilt = 0
        isWalking = false
        zzzTimer?.invalidate()
        zzzList.removeAll()
        walkingTimer?.invalidate()
    }

    func updateDragVelocity(deltaX: CGFloat) {
        let targetTilt = deltaX * -1.8
        dragTilt = max(-30.0, min(30.0, targetTilt))
    }

    func stopDragging() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            dragTilt = 0
        }
        state = .awake
        isWalking = false
        checkGravity()
        startActivityTimer()
    }

    // MARK: - Sleep

    func fallAsleep() {
        state = .sleeping
        isWalking = false
        startZZZTimer()
        walkingTimer?.invalidate()
    }

    func wakeUp() {
        state = .awake
        isWalking = false
        zzzTimer?.invalidate()
        zzzList.removeAll()
        checkGravity()
        startActivityTimer()
    }

    // MARK: - Gravity

    func checkGravity() {
        guard state != .dragging else { return }

        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0 is CatWindow }) else { return }
            let screen = window.screen ?? NSScreen.main
            let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
            let groundY = screenFrame.minY

            let currentY = window.frame.origin.y
            if currentY > groundY {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.6
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    window.animator().setFrameOrigin(NSPoint(x: window.frame.origin.x, y: groundY))
                }, completionHandler: {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.15
                        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                        window.animator().setFrameOrigin(NSPoint(x: window.frame.origin.x, y: groundY + 8))
                    }, completionHandler: {
                        NSAnimationContext.runAnimationGroup({ context in
                            context.duration = 0.1
                            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                            window.animator().setFrameOrigin(NSPoint(x: window.frame.origin.x, y: groundY))
                        })
                    })
                })
            }
        }
    }

    // MARK: - ZZZ

    private func startZZZTimer() {
        zzzTimer?.invalidate()
        zzzTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .sleeping else { return }

            let newZZZ = ZZZItem(
                offset: CGSize(width: Double.random(in: 25...40), height: -20),
                opacity: 1.0,
                scale: 0.5
            )

            DispatchQueue.main.async {
                self.zzzList.append(newZZZ)

                if Double.random(in: 0...1) < 0.35 {
                    self.triggerLegTwitch()
                }

                let index = self.zzzList.count - 1
                withAnimation(.easeOut(duration: 3.5)) {
                    self.zzzList[index].offset.height = -90 - Double.random(in: 10...30)
                    self.zzzList[index].offset.width += Double.random(in: 10...30)
                    self.zzzList[index].opacity = 0.0
                    self.zzzList[index].scale = 1.3
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) {
                    if !self.zzzList.isEmpty {
                        self.zzzList.removeFirst()
                    }
                }
            }
        }
    }

    private func triggerLegTwitch() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            legsTwitch = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                self.legsTwitch = false
            }
        }
    }

    // MARK: - Blink

    private func startBlinkTimer() {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .awake else { return }
            withAnimation(.linear(duration: 0.08)) {
                self.eyeClosedRatio = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.linear(duration: 0.08)) {
                    self.eyeClosedRatio = 0.0
                }
            }
            if Double.random(in: 0...1) < 0.25 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.linear(duration: 0.08)) {
                        self.eyeClosedRatio = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.linear(duration: 0.08)) {
                            self.eyeClosedRatio = 0.0
                        }
                    }
                }
            }
        }
    }

    // MARK: - Activity Timer

    private func startActivityTimer() {
        activityTimer?.invalidate()
        activityTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state != .dragging else { return }

            let dice = Double.random(in: 0...1)
            if self.state == .awake && !self.isWalking {
                if dice < 0.15 {
                    self.fallAsleep()
                } else if dice < 0.55 {
                    self.startWalking()
                }
            } else if self.state == .sleeping {
                if dice < 0.25 {
                    self.wakeUp()
                }
            }
        }
    }

    // MARK: - Walking

    private func startWalking() {
        guard state == .awake else { return }
        walkingTimer?.invalidate()

        let walkToLeft = Double.random(in: 0...1) < 0.5
        isFacingLeft = walkToLeft
        isWalking = true
        walkLegPhase = 0

        let steps = Int.random(in: 25...50)
        var currentStep = 0
        let stepInterval = 0.05
        let stepDistance: CGFloat = walkToLeft ? -2.5 : 2.5

        let walkPastScreen = Double.random(in: 0...1) < 0.35

        walkingTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.state != .awake {
                self.isWalking = false
                timer.invalidate()
                return
            }

            currentStep += 1
            // Advance leg animation phase
            self.walkLegPhase += 0.35

            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0 is CatWindow }) {
                    var frame = window.frame
                    let screen = window.screen ?? NSScreen.main
                    let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)

                    let newX = frame.origin.x + stepDistance

                    if !walkPastScreen {
                        let minX = screenFrame.minX - 30
                        let maxX = screenFrame.maxX - frame.width + 30

                        if newX < minX || newX > maxX {
                            self.isFacingLeft.toggle()
                            self.isWalking = false
                            timer.invalidate()
                            return
                        }
                    } else {
                        let isOffLeft = newX < (screenFrame.minX - frame.width + 45)
                        let isOffRight = newX > (screenFrame.maxX - 45)

                        if isOffLeft || isOffRight {
                            self.isWalking = false
                            timer.invalidate()
                            self.triggerPeeking(isLeft: isOffLeft)
                            return
                        }
                    }

                    frame.origin.x = newX
                    window.setFrame(frame, display: true)
                }
            }

            if currentStep >= steps {
                self.isWalking = false
                timer.invalidate()
            }
        }
    }

    private func triggerPeeking(isLeft: Bool) {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0 is CatWindow }) else { return }
            var frame = window.frame
            let screen = window.screen ?? NSScreen.main
            let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)

            self.isFacingLeft = !isLeft

            if isLeft {
                frame.origin.x = screenFrame.minX - frame.width + 45
            } else {
                frame.origin.x = screenFrame.maxX - 45
            }

            window.setFrame(frame, display: true)

            let peekingDuration = Double.random(in: 8.0...18.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + peekingDuration) { [weak self] in
                guard let self = self, self.state == .awake else { return }
                self.walkBackOntoScreen(fromLeft: isLeft)
            }
        }
    }

    private func walkBackOntoScreen(fromLeft: Bool) {
        guard state == .awake else { return }

        isFacingLeft = !fromLeft
        isWalking = true
        walkLegPhase = 0

        let steps = 35
        var currentStep = 0
        let stepInterval = 0.05
        let stepDistance: CGFloat = fromLeft ? 2.5 : -2.5

        walkingTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.state != .awake {
                self.isWalking = false
                timer.invalidate()
                return
            }

            currentStep += 1
            self.walkLegPhase += 0.35

            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0 is CatWindow }) {
                    var frame = window.frame
                    frame.origin.x += stepDistance
                    window.setFrame(frame, display: true)
                }
            }

            if currentStep >= steps {
                self.isWalking = false
                timer.invalidate()
            }
        }
    }
}
