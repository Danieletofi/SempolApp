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

// MARK: - Character Configuration

struct SoundFile {
    let fileName: String
    let fileExtension: String
}

struct CharacterConfig {
    let id: String
    let layoutFileName: String
    /// Maps layer names (from the layout JSON) to their sound files.
    let soundMap: [String: SoundFile]
}

extension CharacterConfig {
    static let elf = CharacterConfig(
        id: "elf",
        layoutFileName: "PortraitLayout",
        soundMap: [
            "card_1_capelli":      SoundFile(fileName: "suono-elfo-capelli",      fileExtension: "mp3"),
            "card_1_orecchio_sx":  SoundFile(fileName: "suono-elfo-orecchio-sx",  fileExtension: "mp3"),
            "card_1_orecchio_dx":  SoundFile(fileName: "suono-elfo-orecchio-dx",  fileExtension: "mp3"),
            "card_1_occhio_sx":    SoundFile(fileName: "suono-elfo-occhio-sx",    fileExtension: "mp3"),
            "card_1_occhio_dx":    SoundFile(fileName: "suono-elfo-occhio-dx",    fileExtension: "mp3"),
            "card_1_naso":         SoundFile(fileName: "suono-elfo-naso",         fileExtension: "mp3"),
            "card_1_bocca":        SoundFile(fileName: "suono-elfo-bocca",        fileExtension: "mp3"),
        ]
    )

    static let orc = CharacterConfig(
        id: "orc",
        layoutFileName: "OrcPortraitLayout",
        soundMap: [
            "card_3_orecchio_sx":  SoundFile(fileName: "suono-orco-orecchio_sx",  fileExtension: "wav"),
            "card_3_orecchio_dx":  SoundFile(fileName: "suono-orco-orecchio_dx",  fileExtension: "wav"),
            "card_3_occhio_sx":    SoundFile(fileName: "suono-orco-occhio_sx",    fileExtension: "wav"),
            "card_3_occhio_sopra": SoundFile(fileName: "suono-orco-occhiosopra",  fileExtension: "wav"),
            "card_3_occhio_dx":    SoundFile(fileName: "suono-orco-occhio_dx",    fileExtension: "wav"),
            "card_3_naso":         SoundFile(fileName: "suono-orco-naso",         fileExtension: "wav"),
            "card_3_bocca":        SoundFile(fileName: "suono-orco-bocca",        fileExtension: "wav"),
        ]
    )

    static let gremlin = CharacterConfig(
        id: "gremlin",
        layoutFileName: "GremlinPortraitLayout",
        soundMap: [
            "card_2_ciglio":       SoundFile(fileName: "suoni_gremlin_ciglio",      fileExtension: "wav"),
            "card_2_orecchio_sx":  SoundFile(fileName: "suoni_gremlin_orecchio_sx", fileExtension: "wav"),
            "card_2_orecchio_dx":  SoundFile(fileName: "suoni_gremlin_orecchio_dx", fileExtension: "wav"),
            "card_2_occhio_sx":    SoundFile(fileName: "suoni_gremlin_occhio_sx",   fileExtension: "wav"),
            "card_2_occhio_dx":    SoundFile(fileName: "suoni_gremlin_occhio_dx",   fileExtension: "wav"),
            "card_2_naso":         SoundFile(fileName: "suoni_gremlin_naso",        fileExtension: "wav"),
            "card_2_bocca":        SoundFile(fileName: "suoni_gremlin_bocca",       fileExtension: "wav"),
        ]
    )
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
    private var effectPlayers: [String: AVAudioPlayer] = [:]

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

    /// Plays a sound effect by file name and extension. Players are cached by key.
    func playSoundEffect(fileName: String, fileExtension: String) {
        let key = "\(fileName).\(fileExtension)"
        let player: AVAudioPlayer

        if let existing = effectPlayers[key] {
            player = existing
        } else {
            guard let newPlayer = makePlayer(fileName: fileName, fileExtension: fileExtension) else {
                return
            }
            effectPlayers[key] = newPlayer
            player = newPlayer
        }

        player.currentTime = 0
        player.play()
    }

    /// Convenience: play a sound from a CharacterConfig's soundMap for a given layer name.
    func playEffect(forLayer layerName: String, config: CharacterConfig) {
        guard let sound = config.soundMap[layerName] else { return }
        playSoundEffect(fileName: sound.fileName, fileExtension: sound.fileExtension)
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
