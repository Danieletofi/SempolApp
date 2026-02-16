import SwiftUI
import UIKit

/// Simple model for the gallery cards on the home screen.
struct SempolCard: Identifiable, Hashable {
    enum CardType {
        case elf
        case placeholder
    }

    let id = UUID()
    let type: CardType
    let title: String
}

struct HomeView: View {
    @State private var cards: [SempolCard] = [
        .init(type: .placeholder, title: "Card 1"),
        .init(type: .elf, title: "Elfo"),
        .init(type: .placeholder, title: "Card 3")
    ]

    @State private var currentIndex: Int = 1 // start focused on the Elfo card

    private static let launchBackground = Color(red: 0.975, green: 0.975, blue: 0.98)

    var body: some View {
        ZStack {
            Self.launchBackground
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Debug: Show that our code is running
                Text("Sempol App - HomeView")
                    .font(.title)
                    .foregroundColor(.black)
                    .padding()

                // Main cards area – simplified version of the Figma selector
                HStack(spacing: 40) {
                    ForEach(cards.indices, id: \.self) { index in
                        let card = cards[index]
                        CardPreview(card: card, isFocused: index == currentIndex)
                            .onTapGesture {
                                handleCardTap(card: card)
                            }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Navigation arrows under the cards
                HStack(spacing: 40) {
                    ArrowButton(direction: .left) {
                        moveLeft()
                    }
                    ArrowButton(direction: .right) {
                        moveRight()
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func moveLeft() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
    }

    private func moveRight() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % cards.count
    }

    private func handleCardTap(card: SempolCard) {
        switch card.type {
        case .elf:
            // Navigation is handled via NavigationLink embedded in CardPreview
            break
        case .placeholder:
            // Future cards – no action for now
            break
        }
    }
}

private struct CardPreview: View {
    let card: SempolCard
    let isFocused: Bool

    var body: some View {
        Group {
            switch card.type {
            case .elf:
                NavigationLink {
                    ElfPlayView()
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            case .placeholder:
                cardContent
                    .overlay(
                        Text("Coming soon")
                            .font(.headline)
                            .foregroundColor(Color.black.opacity(0.6))
                    )
            }
        }
        .frame(maxHeight: 500)
    }

    private var cardContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .strokeBorder(Color.black, lineWidth: 6)
                .background(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(Color.white)
                )

            // Card preview image - using the actual preview asset
            if card.type == .elf {
                if let image = UIImage(named: "card-ritratto-1") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    // Fallback if image not found
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("card-ritratto-1")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                // Placeholder for future cards
                Color.gray.opacity(0.3)
            }
        }
        .aspectRatio(1024 / 1366, contentMode: .fit)
        .rotationEffect(.degrees(isFocused ? 0 : (cardRotation)))
                .shadow(color: Color.black.opacity(isFocused ? 0.1 : 0.2), radius: isFocused ? 8 : 12, x: 0, y: 8)
        .scaleEffect(isFocused ? 1.05 : 0.95)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }

    private var cardRotation: Double {
        // Give side cards a small playful tilt
        switch card.type {
        case .elf:
            return 0
        case .placeholder:
            return 4
        }
    }
}

private struct ArrowButton: View {
    enum Direction {
        case left
        case right
    }

    let direction: Direction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.black, lineWidth: 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )

                Group {
                    if let image = UIImage(named: "Icona_freccia") {
                        Image(uiImage: image)
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
            }
        }
        .frame(width: 120, height: 120)
        .buttonStyle(.plain)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
        .previewInterfaceOrientation(.portrait)
    }
}

