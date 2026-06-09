import SwiftUI
import Foundation

struct CatView: View {
    @ObservedObject var viewModel: CatViewModel

    @State private var tailSwing: CGFloat = 0.0
    @State private var breathingScale: CGFloat = 1.0

    // Colors
    private let fur = Color(red: 0.95, green: 0.58, blue: 0.26)
    private let darkFur = Color(red: 0.82, green: 0.44, blue: 0.15)
    private let belly = Color(red: 0.98, green: 0.94, blue: 0.88)
    private let pink = Color(red: 0.98, green: 0.73, blue: 0.73)
    private let dark = Color(red: 0.16, green: 0.14, blue: 0.14)
    private let whiskerCol = Color.black.opacity(0.3)
    private let shadowCol = Color.black.opacity(0.12)

    var body: some View {
        ZStack {
            // ZZZ particles
            if viewModel.state == .sleeping {
                ForEach(viewModel.zzzList) { item in
                    Text("Z")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(item.offset)
                        .opacity(item.opacity)
                        .scaleEffect(item.scale)
                }
            }

            VStack {
                Spacer()
                ZStack {
                    switch viewModel.state {
                    case .sleeping:
                        sleepingCatView
                            .scaleEffect(x: 1.0, y: breathingScale, anchor: .bottom)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                                    breathingScale = 1.03
                                }
                            }
                    case .dragging:
                        draggingCatView
                            .rotationEffect(.degrees(viewModel.dragTilt))
                            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.dragTilt)
                    case .awake:
                        if viewModel.isWalking {
                            walkingCatView
                        } else {
                            sittingCatView
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                                        tailSwing = 12.0
                                    }
                                }
                        }
                    }
                }
                .frame(width: 180, height: 180)
                .scaleEffect(0.75)
                Spacer()
            }
            .frame(width: 150, height: 150)
            .scaleEffect(x: (viewModel.state != .dragging && viewModel.isFacingLeft) ? -1.0 : 1.0, y: 1.0)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isFacingLeft)
        }
    }

    // ──────────────────────────────────────────────
    // MARK: - SITTING CAT
    // ──────────────────────────────────────────────

    private var sittingCatView: some View {
        ZStack {
            // Ground shadow
            Ellipse().fill(shadowCol).frame(width: 80, height: 7).offset(y: 56)

            // Tail behind body (redesigned with a smooth curve and gradual tip transition)
            sittingTail

            // Lower body (wide haunches)
            Ellipse()
                .fill(fur)
                .frame(width: 68, height: 50)
                .offset(y: 30)

            // Upper body / chest
            Ellipse()
                .fill(fur)
                .frame(width: 58, height: 46)
                .offset(y: 12)

            // Belly patch
            Ellipse()
                .fill(belly)
                .frame(width: 36, height: 34)
                .offset(y: 28)

            // Left thigh crease & stripes (defines the hind leg shape, positioned low)
            Path { path in
                path.move(to: CGPoint(x: 1.5, y: 1))
                path.addQuadCurve(to: CGPoint(x: 13.5, y: 19), control: CGPoint(x: 2.0, y: 15))
            }
            .stroke(darkFur, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            .frame(width: 15, height: 20)
            .offset(x: -26, y: 41)
            
            Capsule().fill(darkFur).frame(width: 8, height: 2.5).rotationEffect(.degrees(-15)).offset(x: -28, y: 38)
            Capsule().fill(darkFur).frame(width: 7, height: 2).rotationEffect(.degrees(-15)).offset(x: -29, y: 30)

            // Right thigh crease & stripes (positioned low)
            Path { path in
                path.move(to: CGPoint(x: 13.5, y: 1))
                path.addQuadCurve(to: CGPoint(x: 1.5, y: 19), control: CGPoint(x: 13.0, y: 15))
            }
            .stroke(darkFur, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            .frame(width: 15, height: 20)
            .offset(x: 26, y: 41)

            Capsule().fill(darkFur).frame(width: 8, height: 2.5).rotationEffect(.degrees(15)).offset(x: 28, y: 38)
            Capsule().fill(darkFur).frame(width: 7, height: 2).rotationEffect(.degrees(15)).offset(x: 29, y: 30)

            // Front paws
            RoundedRectangle(cornerRadius: 6)
                .fill(belly)
                .frame(width: 16, height: 12)
                .offset(x: -14, y: 52)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(belly)
                .frame(width: 16, height: 12)
                .offset(x: 14, y: 52)

            // Head
            catHead(eyeYOff: -15, headYOff: -14, earYOff: -34, showWhiskers: true)
        }
    }

    private func calculateSubsegment(p0: CGPoint, p1: CGPoint, p2: CGPoint, t0: CGFloat) -> (q0: CGPoint, q1: CGPoint, q2: CGPoint) {
        let mt = 1.0 - t0
        let q0x = mt * mt * p0.x + 2.0 * mt * t0 * p1.x + t0 * t0 * p2.x
        let q0y = mt * mt * p0.y + 2.0 * mt * t0 * p1.y + t0 * t0 * p2.y
        let q1x = mt * p1.x + t0 * p2.x
        let q1y = mt * p1.y + t0 * p2.y
        return (CGPoint(x: q0x, y: q0y), CGPoint(x: q1x, y: q1y), p2)
    }

    private var sittingTail: some View {
        Canvas { context, size in
            let t0: CGFloat = 0.82
            
            let p0 = CGPoint(x: size.width * 0.2, y: size.height * 0.95)
            let p1 = CGPoint(x: size.width * 0.75, y: size.height * 0.8)
            let p2 = CGPoint(x: size.width * 0.9, y: size.height * 0.15 + tailSwing)
            
            var path = Path()
            path.move(to: p0)
            path.addQuadCurve(to: p2, control: p1)
            context.stroke(path, with: .color(fur), style: StrokeStyle(lineWidth: 12, lineCap: .round))
            
            // Calculate mathematically exact subsegment control points for the tip (from t = t0 to 1)
            let sub = calculateSubsegment(p0: p0, p1: p1, p2: p2, t0: t0)
            
            var tip = Path()
            tip.move(to: sub.q0)
            tip.addQuadCurve(to: sub.q2, control: sub.q1)
            context.stroke(tip, with: .color(darkFur), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        }
        .frame(width: 50, height: 60)
        .offset(x: 26, y: 14)
    }

    // ──────────────────────────────────────────────
    // MARK: - WALKING CAT (side view, on all fours)
    // ──────────────────────────────────────────────

    private var walkingCatView: some View {
        let phase = viewModel.walkLegPhase
        let legAngle1 = sin(phase) * 22.0
        let legAngle2 = sin(phase + .pi) * 22.0

        return ZStack {
            // Ground shadow
            Ellipse().fill(shadowCol).frame(width: 100, height: 6).offset(y: 48)

            // Tail (securely attached to the body corner)
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: size.width * 0.5, y: size.height))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.15, y: size.height * 0.05),
                    control1: CGPoint(x: size.width * 0.3, y: size.height * 0.6),
                    control2: CGPoint(x: size.width * 0.0, y: size.height * 0.2)
                )
                context.stroke(path, with: .color(fur), style: StrokeStyle(lineWidth: 9, lineCap: .round))

                var tip = Path()
                tip.move(to: CGPoint(x: size.width * 0.22, y: size.height * 0.2))
                tip.addQuadCurve(
                    to: CGPoint(x: size.width * 0.15, y: size.height * 0.05),
                    control: CGPoint(x: size.width * 0.1, y: size.height * 0.12)
                )
                context.stroke(tip, with: .color(darkFur), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            }
            .frame(width: 32, height: 44)
            .offset(x: -29, y: -20)

            // Back legs
            walkingLeg(angle: legAngle2, xOff: -22, yOff: 24, isFar: true)
            walkingLeg(angle: legAngle1, xOff: -18, yOff: 24, isFar: false)

            // Front legs
            walkingLeg(angle: legAngle1, xOff: 18, yOff: 22, isFar: true)
            walkingLeg(angle: legAngle2, xOff: 22, yOff: 22, isFar: false)

            // Body
            Capsule()
                .fill(fur)
                .frame(width: 70, height: 38)
                .offset(y: 6)

            // Belly (small chest-belly patch visible from side)
            Capsule()
                .fill(belly)
                .frame(width: 25, height: 12)
                .offset(x: 12, y: 16)

            // Body stripes
            Capsule().fill(darkFur).frame(width: 3, height: 10).rotationEffect(.degrees(15)).offset(x: -10, y: 0)
            Capsule().fill(darkFur).frame(width: 3, height: 12).offset(x: -2, y: -2)
            Capsule().fill(darkFur).frame(width: 3, height: 10).rotationEffect(.degrees(-15)).offset(x: 6, y: 0)

            // Head (at front/right of body, grouped to allow wiggling and eye-tracking)
            let horizScale = (viewModel.state != .dragging && viewModel.isFacingLeft) ? -1.0 : 1.0
            let currentEyeOffsetX = viewModel.eyeOffsetX * horizScale
            let currentEyeOffsetY = viewModel.eyeOffsetY

            ZStack {
                Ellipse()
                    .fill(fur)
                    .frame(width: 50, height: 44)
                    .offset(x: 40, y: -4)

                // Cheek white
                Ellipse()
                    .fill(belly)
                    .frame(width: 20, height: 12)
                    .offset(x: 45, y: 6)

                // Ears (only one ear visible from side profile)
                ZStack {
                    EarShape(isLeft: true).fill(fur)
                    EarShape(isLeft: true).fill(pink).scaleEffect(0.5, anchor: .bottom).offset(x: 1, y: -2)
                }
                .frame(width: 14, height: 18)
                .offset(x: 35, y: -24)

                // Forehead stripes
                HStack(spacing: 1.5) {
                    RoundedRectangle(cornerRadius: 1).fill(darkFur).frame(width: 2, height: 5)
                    RoundedRectangle(cornerRadius: 1).fill(darkFur).frame(width: 2, height: 7)
                    RoundedRectangle(cornerRadius: 1).fill(darkFur).frame(width: 2, height: 5)
                }
                .offset(x: 38, y: -20)

                // Eye (with tracking)
                ZStack {
                    Circle().fill(dark).frame(width: 10, height: 10)
                    Circle().fill(Color.white).frame(width: 4, height: 4)
                        .offset(x: -1.5 + currentEyeOffsetX * 0.6, y: -2.0 + currentEyeOffsetY * 0.6)
                }
                .offset(x: 47, y: -6)

                // Nose
                Triangle()
                    .fill(pink)
                    .frame(width: 4.5, height: 3.5)
                    .rotationEffect(.degrees(180))
                    .offset(x: 56, y: -1)

                // Whiskers
                Capsule().fill(whiskerCol).frame(width: 14, height: 1).rotationEffect(.degrees(-8)).offset(x: 64, y: 2)
                Capsule().fill(whiskerCol).frame(width: 16, height: 1).offset(x: 66, y: 5)
            }
            .frame(width: 180, height: 180)
            .offset(x: viewModel.headOffsetX * horizScale * 0.5, y: viewModel.headOffsetY * 0.5)
            .rotationEffect(.degrees(viewModel.headRotation * horizScale * 0.5))
        }
    }

    private func walkingLeg(angle: CGFloat, xOff: CGFloat, yOff: CGFloat, isFar: Bool) -> some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(isFar ? darkFur : fur)
                .frame(width: 9, height: 22)
            RoundedRectangle(cornerRadius: 3)
                .fill(belly)
                .frame(width: 10, height: 6)
                .offset(y: 17)
        }
        .rotationEffect(.degrees(angle), anchor: .top)
        .offset(x: xOff, y: yOff)
    }

    // ──────────────────────────────────────────────
    // MARK: - SLEEPING CAT
    // ──────────────────────────────────────────────

    private var sleepingCatView: some View {
        ZStack {
            // Shadow
            Ellipse().fill(shadowCol).frame(width: 100, height: 8).offset(y: 40)

            // Tail wrapping around body front
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.35))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.82, y: size.height * 0.58),
                    control1: CGPoint(x: size.width * 0.2, y: size.height * 0.8),
                    control2: CGPoint(x: size.width * 0.65, y: size.height * 0.85)
                )
                context.stroke(path, with: .color(fur), style: StrokeStyle(lineWidth: 12, lineCap: .round))

                var tip = Path()
                tip.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.35))
                tip.addQuadCurve(
                    to: CGPoint(x: size.width * 0.25, y: size.height * 0.58),
                    control: CGPoint(x: size.width * 0.12, y: size.height * 0.52)
                )
                context.stroke(tip, with: .color(darkFur), style: StrokeStyle(lineWidth: 12, lineCap: .round))
            }
            .frame(width: 110, height: 64)
            .offset(x: -4, y: 14)

            // Curled body
            Ellipse().fill(fur).frame(width: 96, height: 60).offset(y: 8)

            // Body stripes
            Canvas { context, size in
                for i in 0..<3 {
                    let y = 0.28 + Double(i) * 0.18
                    var stripe = Path()
                    stripe.move(to: CGPoint(x: size.width * 0.18, y: size.height * y))
                    stripe.addQuadCurve(
                        to: CGPoint(x: size.width * 0.52, y: size.height * y),
                        control: CGPoint(x: size.width * 0.35, y: size.height * (y + 0.08))
                    )
                    context.stroke(stripe, with: .color(darkFur), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
            .frame(width: 96, height: 60)
            .offset(y: 8)

            // Belly visible on right
            Ellipse().fill(belly).frame(width: 28, height: 38).rotationEffect(.degrees(-15)).offset(x: 28, y: 11)

            // Head (resting on the right side of body)
            Ellipse().fill(fur).frame(width: 52, height: 40).rotationEffect(.degrees(10)).offset(x: 24, y: -12)

            // Left ear
            ZStack {
                EarShape(isLeft: true).fill(fur)
                EarShape(isLeft: true).fill(pink).scaleEffect(0.5, anchor: .bottom).offset(x: 1, y: -2)
            }
            .frame(width: 14, height: 18)
            .rotationEffect(.degrees(-5))
            .offset(x: 10, y: -30)

            // Right ear
            ZStack {
                EarShape(isLeft: false).fill(fur)
                EarShape(isLeft: false).fill(pink).scaleEffect(0.5, anchor: .bottom).offset(x: -1, y: -2)
            }
            .frame(width: 14, height: 18)
            .rotationEffect(.degrees(15))
            .offset(x: 35, y: -26)

            // Forehead stripes
            HStack(spacing: 1.5) {
                RoundedRectangle(cornerRadius: 1).fill(darkFur).frame(width: 2, height: 5)
                RoundedRectangle(cornerRadius: 1).fill(darkFur).frame(width: 2, height: 7)
                RoundedRectangle(cornerRadius: 1).fill(darkFur).frame(width: 2, height: 5)
            }
            .rotationEffect(.degrees(10))
            .offset(x: 22, y: -28)

            // Closed eyes
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                var leftEye = Path()
                leftEye.move(to: CGPoint(x: cx - 14, y: cy))
                leftEye.addQuadCurve(to: CGPoint(x: cx - 6, y: cy), control: CGPoint(x: cx - 10, y: cy + 3))
                context.stroke(leftEye, with: .color(dark), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

                var rightEye = Path()
                rightEye.move(to: CGPoint(x: cx + 3, y: cy + 1))
                rightEye.addQuadCurve(to: CGPoint(x: cx + 11, y: cy + 1), control: CGPoint(x: cx + 7, y: cy + 4))
                context.stroke(rightEye, with: .color(dark), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
            .frame(width: 48, height: 11)
            .rotationEffect(.degrees(8))
            .offset(x: 22, y: -12)

            // Nose
            Circle().fill(pink).frame(width: 4, height: 4).offset(x: 22, y: -6)

            // Visible front paw (twitching)
            RoundedRectangle(cornerRadius: 5)
                .fill(belly)
                .frame(width: 14, height: 9)
                .rotationEffect(.degrees(viewModel.legsTwitch ? -20 : 0), anchor: .trailing)
                .offset(x: 40, y: 18)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: viewModel.legsTwitch)

            RoundedRectangle(cornerRadius: 5)
                .fill(belly)
                .frame(width: 11, height: 8)
                .offset(x: 35, y: 27)
        }
    }

    // ──────────────────────────────────────────────
    // MARK: - DRAGGING CAT
    // ──────────────────────────────────────────────

    private var draggingCatView: some View {
        let sway = viewModel.dragTilt * 0.7

        return ZStack {
            // Tail hanging down (drawn with padding to prevent rounded linecaps from being clipped at bottom)
            Canvas { context, size in
                let t0: CGFloat = 0.82
                
                let p0 = CGPoint(x: size.width / 2, y: 6)
                let p1 = CGPoint(x: size.width / 2 + 6, y: size.height * 0.5)
                let p2 = CGPoint(x: size.width / 2 - 8, y: size.height - 8)
                
                var path = Path()
                path.move(to: p0)
                path.addQuadCurve(to: p2, control: p1)
                context.stroke(path, with: .color(fur), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                
                // Calculate mathematically exact subsegment control points for the tip (from t = t0 to 1)
                let sub = calculateSubsegment(p0: p0, p1: p1, p2: p2, t0: t0)
                
                var tip = Path()
                tip.move(to: sub.q0)
                tip.addQuadCurve(to: sub.q2, control: sub.q1)
                context.stroke(tip, with: .color(darkFur), style: StrokeStyle(lineWidth: 10, lineCap: .round))
            }
            .frame(width: 36, height: 60)
            .rotationEffect(.degrees(sway * 0.8), anchor: .top)
            .offset(x: 4, y: 38)

            // Back legs
            HStack(spacing: 20) {
                danglingLeg(swayDeg: sway, length: 34)
                danglingLeg(swayDeg: sway * 0.9, length: 34)
            }
            .offset(y: 42)

            // Stretched body
            RoundedRectangle(cornerRadius: 22)
                .fill(fur)
                .frame(width: 50, height: 88)
                .offset(y: -2)

            // Belly
            RoundedRectangle(cornerRadius: 12)
                .fill(belly)
                .frame(width: 30, height: 58)
                .offset(y: 6)

            // Body stripes
            Capsule().fill(darkFur).frame(width: 7, height: 2.5).offset(x: -23, y: -8)
            Capsule().fill(darkFur).frame(width: 7, height: 2.5).offset(x: 23, y: -8)
            Capsule().fill(darkFur).frame(width: 7, height: 2.5).offset(x: -21, y: 3)
            Capsule().fill(darkFur).frame(width: 7, height: 2.5).offset(x: 21, y: 3)

            // Front arms
            HStack(spacing: 36) {
                danglingArm(swayDeg: sway * 1.1, length: 28)
                danglingArm(swayDeg: sway * 1.05, length: 28)
            }
            .offset(y: -10)

            // Head (uses neutral face options to match sitting head size and look)
            catHead(eyeYOff: -15, headYOff: -14, earYOff: -34, showWhiskers: false, isOpenMouth: false, isSurprised: false)
                .offset(y: -30)
        }
    }

    private func danglingLeg(swayDeg: CGFloat, length: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Capsule().fill(fur).frame(width: 12, height: length)
            RoundedRectangle(cornerRadius: 4).fill(belly).frame(width: 12, height: 10).offset(y: length - 10)
        }
        .rotationEffect(.degrees(swayDeg), anchor: .top)
    }

    private func danglingArm(swayDeg: CGFloat, length: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Capsule().fill(fur).frame(width: 10, height: length)
            RoundedRectangle(cornerRadius: 4).fill(belly).frame(width: 10, height: 9).offset(y: length - 9)
        }
        .rotationEffect(.degrees(swayDeg), anchor: .top)
    }

    // ──────────────────────────────────────────────
    // MARK: - Reusable Head
    // ──────────────────────────────────────────────

    private func catHead(eyeYOff: CGFloat, headYOff: CGFloat, earYOff: CGFloat, showWhiskers: Bool, isOpenMouth: Bool = false, isSurprised: Bool = false) -> some View {
        let horizScale = (viewModel.state != .dragging && viewModel.isFacingLeft) ? -1.0 : 1.0

        return ZStack {
            // Ears
            ZStack {
                EarShape(isLeft: true).fill(fur)
                EarShape(isLeft: true).fill(pink).scaleEffect(0.55, anchor: .bottom).offset(x: 2, y: -2)
            }
            .frame(width: 22, height: 24)
            .offset(x: -20, y: earYOff)

            ZStack {
                EarShape(isLeft: false).fill(fur)
                EarShape(isLeft: false).fill(pink).scaleEffect(0.55, anchor: .bottom).offset(x: -2, y: -2)
            }
            .frame(width: 22, height: 24)
            .offset(x: 20, y: earYOff)

            // Head shape
            RoundedRectangle(cornerRadius: 20)
                .fill(fur)
                .frame(width: 66, height: 52)
                .offset(y: headYOff)

            // Cheeks
            Ellipse().fill(belly).frame(width: 44, height: 18).offset(y: headYOff + 16)

            // Forehead stripes
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 1.5).fill(darkFur).frame(width: 3, height: 8)
                RoundedRectangle(cornerRadius: 1.5).fill(darkFur).frame(width: 3, height: 10)
                RoundedRectangle(cornerRadius: 1.5).fill(darkFur).frame(width: 3, height: 8)
            }
            .offset(y: headYOff - 20)

            // Eyes
            awakeEye(xOff: -14, yOff: eyeYOff, isSurprised: isSurprised)
            awakeEye(xOff: 14, yOff: eyeYOff, isSurprised: isSurprised)

            // Nose
            Triangle().fill(pink).frame(width: 6, height: 4.5).rotationEffect(.degrees(180)).offset(y: headYOff + 4)

            // Mouth
            if isOpenMouth {
                Ellipse().fill(pink).frame(width: 5.5, height: 4)
                    .overlay(Ellipse().stroke(dark, lineWidth: 1))
                    .offset(y: headYOff + 12)
            } else {
                Canvas { context, size in
                    var path = Path()
                    let cx = size.width / 2
                    let cy = size.height / 2
                    path.move(to: CGPoint(x: cx - 4, y: cy - 2))
                    path.addQuadCurve(to: CGPoint(x: cx, y: cy + 0.5), control: CGPoint(x: cx - 1.5, y: cy + 0.5))
                    path.addQuadCurve(to: CGPoint(x: cx + 4, y: cy - 2), control: CGPoint(x: cx + 1.5, y: cy + 0.5))
                    context.stroke(path, with: .color(dark), lineWidth: 1.2)
                }
                .frame(width: 16, height: 8)
                .offset(y: headYOff + 9)
            }

            // Whiskers
            if showWhiskers {
                // Left
                Capsule().fill(whiskerCol).frame(width: 20, height: 1.2).rotationEffect(.degrees(-8)).offset(x: -32, y: headYOff + 4)
                Capsule().fill(whiskerCol).frame(width: 22, height: 1.2).offset(x: -33, y: headYOff + 8)
                Capsule().fill(whiskerCol).frame(width: 20, height: 1.2).rotationEffect(.degrees(8)).offset(x: -32, y: headYOff + 12)
                // Right
                Capsule().fill(whiskerCol).frame(width: 20, height: 1.2).rotationEffect(.degrees(8)).offset(x: 32, y: headYOff + 4)
                Capsule().fill(whiskerCol).frame(width: 22, height: 1.2).offset(x: 33, y: headYOff + 8)
                Capsule().fill(whiskerCol).frame(width: 20, height: 1.2).rotationEffect(.degrees(-8)).offset(x: 32, y: headYOff + 12)
            }
        }
        .offset(x: viewModel.headOffsetX * horizScale, y: viewModel.headOffsetY)
        .rotationEffect(.degrees(viewModel.headRotation * horizScale))
    }

    // MARK: - Eye helper

    @ViewBuilder
    private func awakeEye(xOff: CGFloat, yOff: CGFloat, isSurprised: Bool = false) -> some View {
        let horizScale = (viewModel.state != .dragging && viewModel.isFacingLeft) ? -1.0 : 1.0
        let currentEyeOffsetX = viewModel.eyeOffsetX * horizScale
        let currentEyeOffsetY = viewModel.eyeOffsetY

        if isSurprised {
            ZStack {
                Circle().fill(Color.white).frame(width: 14, height: 14)
                Circle().fill(dark).frame(width: 5, height: 5)
                    .offset(x: currentEyeOffsetX * 0.6, y: currentEyeOffsetY * 0.6)
            }
            .offset(x: xOff, y: yOff)
        } else if viewModel.eyeClosedRatio > 0.8 {
            Canvas { context, size in
                var path = Path()
                let cx = size.width / 2
                let cy = size.height / 2
                path.move(to: CGPoint(x: cx - 4, y: cy))
                path.addQuadCurve(to: CGPoint(x: cx + 4, y: cy), control: CGPoint(x: cx, y: cy + 3))
                context.stroke(path, with: .color(dark), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            }
            .frame(width: 12, height: 8)
            .offset(x: xOff, y: yOff)
        } else {
            ZStack {
                Circle().fill(dark).frame(width: 14, height: 14)
                    .scaleEffect(x: 1.0, y: 1.0 - viewModel.eyeClosedRatio)
                Circle().fill(Color.white).frame(width: 5, height: 5)
                    .offset(x: -2.0 + currentEyeOffsetX * 0.6, y: -2.5 + currentEyeOffsetY * 0.6)
                Circle().fill(Color.white).frame(width: 2.5, height: 2.5)
                    .offset(x: 2.0 + currentEyeOffsetX * 0.6, y: 1.5 + currentEyeOffsetY * 0.6)
            }
            .offset(x: xOff, y: yOff)
        }
    }
}

// ──────────────────────────────────────────────
// MARK: - HELPER SHAPES
// ──────────────────────────────────────────────

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct EarShape: Shape {
    let isLeft: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isLeft {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.15),
                control: CGPoint(x: rect.minX, y: rect.height * 0.5)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.maxY - rect.height * 0.35)
            )
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.minY + rect.height * 0.15),
                control: CGPoint(x: rect.maxX, y: rect.height * 0.5)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY),
                control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY - rect.height * 0.35)
            )
        }
        path.closeSubpath()
        return path
    }
}
