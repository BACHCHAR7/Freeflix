import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool
    
    // Logo state
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var logoBlur: CGFloat = 20
    @State private var glowIntensity: Double = 0
    
    // Woosh ambient
    @State private var ambientGlow: Double = 0
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    
    // Underline
    @State private var underlineWidth: CGFloat = 0
    
    private let letters = Array("FREEFLIX")
    private let accentIndices: Set<Int> = [4, 5, 6, 7]
    private let boomTime: Double = 0.880
    
    var body: some View {
        ZStack {
            Color.black
            ambientLayer
            ringLayer
            logoLayer
        }
        .ignoresSafeArea()
        .onAppear(perform: startAnimation)
    }
    
    private var ambientLayer: some View {
        RadialGradient(
            colors: [
                Color.ffAccent.opacity(ambientGlow * 0.25),
                Color.ffAccent.opacity(ambientGlow * 0.05),
                Color.black
            ],
            center: .center,
            startRadius: 0,
            endRadius: 600
        )
        .blur(radius: 50)
    }
    
    private var ringLayer: some View {
        Circle()
            .stroke(
                RadialGradient(
                    colors: [
                        Color.ffAccent.opacity(0.4),
                        Color.ffAccent.opacity(0.1)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                ),
                lineWidth: 2
            )
            .frame(width: 400, height: 400)
            .scaleEffect(ringScale)
            .opacity(ringOpacity)
            .blur(radius: 3)
    }
    
    private var logoLayer: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<letters.count, id: \.self) { index in
                    Text(String(letters[index]))
                        .font(.system(size: 140, weight: .black, design: .default))
                        .foregroundStyle(
                            accentIndices.contains(index)
                            ? AnyShapeStyle(Color.ffAccent)
                            : AnyShapeStyle(Color.white)
                        )
                        .shadow(
                            color: accentIndices.contains(index)
                            ? Color.ffAccent.opacity(glowIntensity * 0.8)
                            : Color.white.opacity(glowIntensity * 0.3),
                            radius: 25
                        )
                        .shadow(
                            color: accentIndices.contains(index)
                            ? Color.ffAccent.opacity(glowIntensity * 0.4)
                            : Color.clear,
                            radius: 60
                        )
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .blur(radius: logoBlur)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.ffAccent.opacity(0),
                            Color.ffAccent,
                            Color.ffAccent,
                            Color.ffAccent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: underlineWidth, height: 4)
                .shadow(color: Color.ffAccent.opacity(0.6), radius: 12)
        }
    }
    
    private func startAnimation() {
        SoundManager.shared.playIntroSound()
        
        // WOOOOOSH (0 -> 0.880s)
        // Glow ambiant monte doucement
        withAnimation(.easeIn(duration: boomTime)) {
            ambientGlow = 0.8
        }
        
        // Ring pulse pendant le woosh
        withAnimation(.easeOut(duration: boomTime * 0.8)) {
            ringOpacity = 0.5
            ringScale = 1.5
        }
        
        // Logo commence a emerger doucement
        withAnimation(.easeIn(duration: boomTime)) {
            logoOpacity = 0.3
            logoScale = 0.85
            logoBlur = 8
        }
        
        // BOOM (0.880s)
        DispatchQueue.main.asyncAfter(deadline: .now() + boomTime) {
            // Logo full reveal
            withAnimation(.easeOut(duration: 0.25)) {
                logoOpacity = 1.0
                logoScale = 1.0
                logoBlur = 0
                glowIntensity = 1.0
                ambientGlow = 1.0
            }
            
            // Ring explose et disparait
            withAnimation(.easeOut(duration: 0.3)) {
                ringScale = 3.0
                ringOpacity = 0
            }
            
            // Underline smooth
            withAnimation(.easeOut(duration: 0.4)) {
                underlineWidth = 720
            }
        }
        
        // Glow settle
        DispatchQueue.main.asyncAfter(deadline: .now() + boomTime + 0.8) {
            withAnimation(.easeInOut(duration: 1.2)) {
                glowIntensity = 0.5
                ambientGlow = 0.6
            }
        }
        
        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                logoOpacity = 0
                glowIntensity = 0
                ambientGlow = 0
                underlineWidth = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            isFinished = true
        }
    }
}

