import Foundation
import AVFoundation

// MARK: - Music Track model

struct MusicTrack: Identifiable, Equatable {
    let id: String
    let title: String
    let genre: String
    let fileName: String
    let fileExtension: String
}

extension MusicTrack {
    static let allTracks: [MusicTrack] = [
        .init(id: "downtown-base", title: "Downtown", genre: "Classic HipHop", fileName: "Downtown-base", fileExtension: "mp3"),
        .init(id: "sunset-vibes", title: "Sunset Vibes", genre: "Lo-fi Beats", fileName: "base_orco", fileExtension: "wav"),
        .init(id: "forest-walk", title: "Forest Walk", genre: "Ambient", fileName: "base_gremlin", fileExtension: "wav")
    ]

    static let defaultTrack = allTracks[0]
}

// MARK: - Elf Sound enum

/// Identifies each tappable part of the elf portrait.
enum ElfSound: CaseIterable {
    case capelli
    case orecchioSinistro
    case orecchioDestro
    case occhioSinistro
    case occhioDestro
    case naso
    case bocca

    /// The exact filename (without extension) for each sound in `Suoni_ritratto_elfo`.
    var fileName: String {
        switch self {
        case .capelli:
            return "suono-elfo-capelli"
        case .orecchioSinistro:
            return "suono-elfo-orecchio-sx"
        case .orecchioDestro:
            return "suono-elfo-orecchio-dx"
        case .occhioSinistro:
            return "suono-elfo-occhio-sx"
        case .occhioDestro:
            return "suono-elfo-occhio-dx"
        case .naso:
            return "suono-elfo-naso"
        case .bocca:
            return "suono-elfo-bocca"
        }
    }
}

// MARK: - Audio Manager

/// Central audio manager: handles the looping base track and the portrait sound effects.
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    // MARK: - Published state

    @Published private(set) var isBasePlaying: Bool = false
    @Published private(set) var currentTrack: MusicTrack = .defaultTrack

    let availableTracks: [MusicTrack] = MusicTrack.allTracks

    // MARK: - Private properties

    private var basePlayer: AVAudioPlayer?
    private var effectPlayers: [ElfSound: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
    }

    // MARK: - Public API

    /// Starts the base track if it has not been created yet, otherwise resumes it.
    func startBaseIfNeeded() {
        if basePlayer == nil {
            basePlayer = makePlayer(fileName: currentTrack.fileName, fileExtension: currentTrack.fileExtension)
            basePlayer?.numberOfLoops = -1
        }

        guard let basePlayer else { return }

        if !basePlayer.isPlaying {
            basePlayer.play()
            updateIsBasePlaying(true)
        }
    }

    func toggleBase() {
        guard let basePlayer else {
            startBaseIfNeeded()
            return
        }

        if basePlayer.isPlaying {
            basePlayer.pause()
            updateIsBasePlaying(false)
        } else {
            basePlayer.play()
            updateIsBasePlaying(true)
        }
    }

    /// Select and switch to a different base track. Always starts playback immediately.
    func selectTrack(_ track: MusicTrack) {
        guard track != currentTrack else { return }

        basePlayer?.stop()
        basePlayer = nil

        currentTrack = track

        basePlayer = makePlayer(fileName: track.fileName, fileExtension: track.fileExtension)
        basePlayer?.numberOfLoops = -1
        basePlayer?.play()
        updateIsBasePlaying(true)
    }

    /// Plays the sound associated with a specific portrait area.
    func playEffect(_ sound: ElfSound) {
        let player: AVAudioPlayer

        if let existing = effectPlayers[sound] {
            player = existing
        } else {
            guard let newPlayer = makePlayer(fileName: sound.fileName, fileExtension: "mp3") else {
                return
            }
            effectPlayers[sound] = newPlayer
            player = newPlayer
        }

        player.currentTime = 0
        player.play()
    }

    // MARK: - Private helpers

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }

    private func makePlayer(fileName: String, fileExtension: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Audio file not found in bundle: \(fileName).\(fileExtension)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("Failed to create AVAudioPlayer for \(fileName): \(error)")
            return nil
        }
    }

    private func updateIsBasePlaying(_ playing: Bool) {
        if Thread.isMainThread {
            isBasePlaying = playing
        } else {
            DispatchQueue.main.async {
                self.isBasePlaying = playing
            }
        }
    }
}
