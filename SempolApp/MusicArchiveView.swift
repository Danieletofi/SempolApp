import SwiftUI
import UIKit

/// Full-screen music archive: lets the user browse and select a base track.
struct MusicArchiveView: View {
    @StateObject private var audioManager = AudioManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 1024, geo.size.height / 1366)

            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header: back button + title
                    header(scale: scale)

                    // Track list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(audioManager.availableTracks) { track in
                                let isActive = track == audioManager.currentTrack
                                TrackRow(
                                    track: track,
                                    isActive: isActive,
                                    scale: scale
                                ) {
                                    audioManager.selectTrack(track)
                                }
                            }
                        }
                        .padding(.horizontal, 24 * scale)
                        .padding(.bottom, 60 * scale)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private func header(scale: CGFloat) -> some View {
        VStack(spacing: 24 * scale) {
            // Back button row
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

            // Hero: icon + title
            VStack(spacing: 16 * scale) {
                if let img = UIImage(named: "Icona_traccia") {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64 * scale, height: 64 * scale)
                } else {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64 * scale, height: 64 * scale)
                        .foregroundColor(.black)
                }

                Text("Archivio Musica")
                    .font(.cherryBombOne(120 * scale))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-120 * scale * 0.2)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40 * scale)
        }
    }
}

// MARK: - Track Row

private struct TrackRow: View {
    let track: MusicTrack
    let isActive: Bool
    let scale: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8 * scale) {
                // Radio button: filled circle when selected, stroke-only when not
                ZStack {
                    if isActive {
                        Circle()
                            .fill(Color.black)
                    } else {
                        Circle()
                            .strokeBorder(Color.black, lineWidth: 2 * scale)
                    }
                }
                .frame(width: 48 * scale, height: 48 * scale)

                Text(track.title)
                    .font(.quicksandMedium(22 * scale))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(track.genre)
                    .font(.quicksandMedium(22 * scale))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 24 * scale)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black)
                .frame(height: 4 * scale)
        }
    }
}
