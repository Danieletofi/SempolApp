import SwiftUI
import UIKit

// MARK: - Card model

private struct SempolCard: Identifiable {
    enum CardType {
        case elf, gremlin, orc
    }

    let id = UUID()
    let type: CardType
    let previewImageName: String
    let rotation: Double

    var isPlayable: Bool { type == .elf }
}

// MARK: - HomeView

struct HomeView: View {
    private let allCards: [SempolCard] = [
        .init(type: .gremlin, previewImageName: "card-ritratto-Gremlin", rotation: -4),
        .init(type: .elf,     previewImageName: "card-ritratto-Elfo",    rotation: 0),
        .init(type: .orc,     previewImageName: "card-ritratto-Orco",    rotation: 4)
    ]

    @State private var centerIndex: Int = 1
    @State private var showCredits: Bool = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            VStack(spacing: 0) {
                // MARK: Section_intro  (node 90-731)
                sectionIntro
                    .frame(width: w, height: h * 0.26)

                // MARK: Card selector  (node 90-915)
                cardCarousel(screenWidth: w, availableHeight: h * 0.56)
                    .frame(width: w, height: h * 0.56)

                // Spacer pushes Credits to bottom (node 90-653)
                Spacer(minLength: 0)

                // MARK: Credits section (node 90-709) - ancorato in basso
                creditsButton
                    .frame(width: w)
                    .padding(.bottom, 24)
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color.white)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showCredits) {
            CreditsView()
        }
    }

    // MARK: - Section Intro (logo + subtitle)

    private var sectionIntro: some View {
        VStack(spacing: 16) {
            Spacer()

            if let logoImg = UIImage(named: "Sampol") {
                Image(uiImage: logoImg)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 304, height: 80)
            }

            Text("Seleziona un musivolto per\ncominciare a suonare")
                .font(.quicksandMedium(40))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
        }
        .frame(maxWidth: 650)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card Carousel

    private func cardCarousel(screenWidth: CGFloat, availableHeight: CGFloat) -> some View {
        let cardAreaHeight = availableHeight - 160
        let cardH = max(cardAreaHeight, 200)
        let cardW = cardH * (1024.0 / 1366.0)
        let gap: CGFloat = 40

        return VStack(spacing: gap) {
            // Cards row with clipping (side cards partially visible)
            HStack(spacing: gap) {
                ForEach(orderedCards.indices, id: \.self) { i in
                    let card = orderedCards[i]
                    let isCentered = (i == 1)
                    cardView(card: card, isCentered: isCentered, cardW: cardW, cardH: cardH)
                }
            }
            .frame(width: screenWidth, height: cardH + 40)
            .clipped()

            // Arrow buttons
            HStack(spacing: gap) {
                ArrowButton(direction: .left) { moveLeft() }
                ArrowButton(direction: .right) { moveRight() }
            }
        }
    }

    private var orderedCards: [SempolCard] {
        guard !allCards.isEmpty else { return [] }
        let n = allCards.count
        let leftIdx  = (centerIndex - 1 + n) % n
        let rightIdx = (centerIndex + 1) % n
        return [allCards[leftIdx], allCards[centerIndex], allCards[rightIdx]]
    }

    @ViewBuilder
    private func cardView(card: SempolCard, isCentered: Bool, cardW: CGFloat, cardH: CGFloat) -> some View {
        let scale: CGFloat = isCentered ? 1.0 : 0.92

        Group {
            if card.isPlayable && isCentered {
                NavigationLink {
                    ElfPlayView()
                } label: {
                    cardBody(card: card, cardW: cardW, cardH: cardH)
                }
                .buttonStyle(.plain)
            } else {
                cardBody(card: card, cardW: cardW, cardH: cardH)
            }
        }
        .frame(width: cardW, height: cardH)
        .rotationEffect(.degrees(card.rotation))
        .scaleEffect(scale)
    }

    private func cardBody(card: SempolCard, cardW: CGFloat, cardH: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white)

            if let image = UIImage(named: card.previewImageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardW, height: cardH)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
            }

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .strokeBorder(Color.black, lineWidth: 6)
        }
        .frame(width: cardW, height: cardH)
    }

    // MARK: - Credits Button

    private var creditsButton: some View {
        Button {
                showCredits = true
            } label: {
                Text("Credits")
                    .font(.quicksandMedium(32))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        Rectangle()
                            .frame(height: 4)
                            .foregroundColor(.black),
                        alignment: .bottom
                    )
            }
            .buttonStyle(.plain)
    }

    // MARK: - Navigation

    private func moveLeft() {
        let n = allCards.count
        guard n > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            centerIndex = (centerIndex - 1 + n) % n
        }
    }

    private func moveRight() {
        let n = allCards.count
        guard n > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            centerIndex = (centerIndex + 1) % n
        }
    }
}

// MARK: - Arrow Button

private struct ArrowButton: View {
    enum Direction { case left, right }

    let direction: Direction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear
                .frame(width: 120, height: 120)
                .handDrawnBorder(cornerRadius: 8, lineWidth: 6)
                .overlay(
                    Group {
                        if let img = UIImage(named: "Icona_freccia") {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(direction == .left ? 180 : 0))
                        } else {
                            Image(systemName: direction == .left ? "arrow.left" : "arrow.right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Credits View (modal, node 93-335)

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let baseWidth: CGFloat = 1024
            let baseHeight: CGFloat = 1366
            let scale = min(geo.size.width / baseWidth, geo.size.height / baseHeight)
            let canvasWidth = baseWidth * scale
            let canvasHeight = baseHeight * scale

            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top area (node 93:336)
                    HStack(spacing: 16 * scale) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 16 * scale) {
                                Color.clear
                                    .frame(width: 120 * scale, height: 120 * scale)
                                    .handDrawnBorder(cornerRadius: 8 * scale, lineWidth: 6 * scale)
                                    .overlay(
                                        Group {
                                            if let img = UIImage(named: "Icona_freccia") {
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 64 * scale, height: 64 * scale)
                                                    .rotationEffect(.degrees(180))
                                            } else {
                                                Image(systemName: "arrow.left")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 64 * scale, height: 64 * scale)
                                                    .foregroundColor(.black)
                                            }
                                        }
                                    )

                                Text("Indietro")
                                    .font(.quicksandMedium(32 * scale))
                                    .foregroundColor(.black)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 16 * scale)
                    .padding(.top, 24 * scale)
                    .frame(height: 144 * scale)

                    // Section_intro (node 93:365) => h 1198, w 992
                    VStack(spacing: 0) {
                        // Section-Credits (node 93:384) => h 931
                        VStack {
                            VStack(spacing: 40 * scale) {
                                Text("Credits!")
                                    .font(.cherryBombOne(120 * scale))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)

                                if let creditImg = UIImage(named: "Sampol_illustrazione_credits") {
                                    Image(uiImage: creditImg)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 318 * scale, height: 318 * scale)
                                }

                                Text("Sample è un esperimento di vibe coding, un set di illustrazioni, e sicuramente un passatempo interessante")
                                    .font(.quicksandMedium(32 * scale))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: 648 * scale)

                                Text("Sample\nv.02")
                                    .font(.quicksandMedium(16 * scale))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 648 * scale)
                        }
                        .frame(width: 992 * scale, height: 931 * scale)

                        // Container-credits-link (node 93:380) => h 267
                        VStack(spacing: 16 * scale) {
                            Text("Design e Illustrazioni by\nDaniele Morganti")
                                .font(.quicksandMedium(22 * scale))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)

                            Link(destination: URL(string: "https://www.danielemorgantidesign.com")!) {
                                Text("www.danielemorgantidesign.com")
                                    .font(.quicksandMedium(32 * scale))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16 * scale)
                                    .padding(.vertical, 8 * scale)
                                    .overlay(
                                        Rectangle()
                                            .frame(height: 4 * scale)
                                            .foregroundColor(.black),
                                        alignment: .bottom
                                    )
                            }
                            .tint(.black)

                            VStack(spacing: 2 * scale) {
                                Text("Code by")
                                    .font(.quicksandMedium(22 * scale))
                                    .foregroundColor(.black)
                                Text("Daniele Morganti")
                                    .font(.quicksandMedium(22 * scale))
                                    .foregroundColor(.black)
                                Text("With a little help of my Ai Friends :)")
                                    .font(.quicksandMedium(16 * scale))
                                    .foregroundColor(.black)
                            }
                            .multilineTextAlignment(.center)
                        }
                        .frame(width: 992 * scale, height: 267 * scale)
                    }
                    .frame(width: 992 * scale, height: 1198 * scale)
                }
                .frame(width: canvasWidth, height: canvasHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Previews

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
        .previewInterfaceOrientation(.portrait)
    }
}
