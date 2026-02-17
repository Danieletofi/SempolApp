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
                        VStack(spacing: 24 * scale) {
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
                        .padding(.horizontal, 40 * scale)
                        .padding(.top, 24 * scale)
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

            // Title
            Text("Archivio Musica")
                .font(.quicksandMedium(40 * scale))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16 * scale)
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
            HStack(spacing: 24 * scale) {
                // State icon: pausa if active (playing), play if inactive
                ZStack {
                    RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                        .fill(Color.white)
                    RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                        .strokeBorder(Color.black, lineWidth: isActive ? 5 * scale : 3 * scale)

                    Group {
                        if isActive {
                            if let img = UIImage(named: "Icona_pausa") {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40 * scale, height: 40 * scale)
                            } else {
                                Image(systemName: "pause.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32 * scale, height: 32 * scale)
                                    .foregroundColor(.black)
                            }
                        } else {
                            if let img = UIImage(named: "Icona_play") {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40 * scale, height: 40 * scale)
                            } else {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32 * scale, height: 32 * scale)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .frame(width: 80 * scale, height: 80 * scale)

                // Track title
                Text(track.title)
                    .font(.quicksandMedium(isActive ? 36 * scale : 32 * scale))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Spacer(minLength: 0)

                // Active indicator tag
                if isActive {
                    Text("In riproduzione")
                        .font(.quicksandMedium(16 * scale))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16 * scale)
                        .padding(.vertical, 8 * scale)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                                .strokeBorder(Color.black, lineWidth: 3 * scale)
                        )
                }
            }
            .padding(.horizontal, 24 * scale)
            .padding(.vertical, 16 * scale)
            .background(
                RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                    .strokeBorder(Color.black, lineWidth: isActive ? 6 * scale : 3 * scale)
            )
        }
        .buttonStyle(.plain)
    }
}
