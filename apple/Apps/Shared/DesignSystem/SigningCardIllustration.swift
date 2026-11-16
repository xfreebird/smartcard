import SwiftUI

/// The signing method illustration contains no personal card details.
struct SigningCardIllustration: View {
    var nfc = true
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 22).fill(Theme.brand.opacity(0.07))
                .frame(width: 210, height: 140).rotationEffect(.degrees(7))
            HStack(spacing: 16) {
                Image(systemName: "person.crop.rectangle.fill").font(.system(size: 43))
                VStack(alignment: .leading, spacing: 10) {
                    Capsule().frame(width: 48, height: 5)
                    Capsule().frame(width: 34, height: 5).opacity(0.5)
                }
            }.foregroundStyle(.white.opacity(0.9))
                .frame(width: 192, height: 122)
                .background(LinearGradient(colors: [Theme.brand, Theme.brand.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
                .rotationEffect(.degrees(-6))
            Image(systemName: nfc ? "wave.3.right" : "creditcard")
                .font(.system(size: 27, weight: .medium)).foregroundStyle(Theme.brand)
                .frame(width: 64, height: 64).background(Theme.surfaceRaised, in: Circle())
                .shadow(color: .black.opacity(0.06), radius: 12, y: 5).offset(x: 12, y: 14)
        }.frame(width: 230, height: 175).padding(.bottom, 6).accessibilityHidden(true)
    }
}
