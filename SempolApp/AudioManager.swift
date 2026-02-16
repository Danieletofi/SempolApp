import Foundation
import AVFoundation

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

/// Central audio manager: handles the looping base track and the portrait sound effects.
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    // MARK: - Published state

    /// Used by SwiftUI to reflect the state of the base track button (play/pause icon).
    @Published private(set) var isBasePlaying: Bool = false

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
            basePlayer = makePlayer(fileName: "Downtown-base", fileExtension: "mp3")
            basePlayer?.numberOfLoops = -1 // infinite loop
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

        // Restart from the beginning on every tap for a crisp, responsive feel.
        player.currentTime = 0
        player.play()
    }

    // MARK: - Private helpers

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.mixWithOthers` allows the app to blend with other audio (e.g. system music) if desired.
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

