import SwiftUI
import UIKit

// MARK: - Portrait layout (canvas 1024x1366, layer bounds from Figma/config)

struct PortraitLayerLayout: Codable {
    var name: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct PortraitLayoutConfig: Codable {
    var canvasWidth: Double
    var canvasHeight: Double
    var layers: [PortraitLayerLayout]
}

/// Generic play screen for any character portrait.
struct PortraitPlayView: View {
    let config: CharacterConfig

    @StateObject private var audioManager = AudioManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var activeLayers: Set<String> = []
    @State private var showMusicArchive: Bool = false

    private var layout: PortraitLayoutConfig? {
        Self.loadPortraitLayout(named: config.layoutFileName)
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            GeometryReader { geometry in
                let viewRect = Self.portraitViewRect(in: geometry.size, layout: layout)
                ZStack {
                    if let layout {
                        PortraitLayeredView(layout: layout, viewSize: viewRect.size, activeLayers: activeLayers)
                            .frame(width: viewRect.width, height: viewRect.height)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        tappableAreasFromLayout(layout: layout, viewRect: viewRect)
                    }
                }
            }

            VStack {
                Spacer()
                bottomControlBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            audioManager.startBaseIfNeeded()
        }
        .fullScreenCover(isPresented: $showMusicArchive) {
            MusicArchiveView()
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Load layout JSON

    private static func loadPortraitLayout(named name: String) -> PortraitLayoutConfig? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PortraitLayoutConfig.self, from: data)
    }

    private static func portraitViewRect(in size: CGSize, layout: PortraitLayoutConfig?) -> CGRect {
        let cw = layout?.canvasWidth ?? 1024
        let ch = layout?.canvasHeight ?? 1366
        let aspect = cw / ch
        var viewW: CGFloat
        var viewH: CGFloat
        if size.width / size.height > aspect {
            viewW = size.height * aspect
            viewH = size.height
        } else {
            viewW = size.width
            viewH = size.width / aspect
        }
        let ox = (size.width - viewW) / 2
        let oy = (size.height - viewH) / 2
        return CGRect(x: ox, y: oy, width: viewW, height: viewH)
    }

    // MARK: - Tappable areas from layout

    private func tappableAreasFromLayout(layout: PortraitLayoutConfig, viewRect: CGRect) -> some View {
        let scaleX = viewRect.width / layout.canvasWidth
        let scaleY = viewRect.height / layout.canvasHeight
        let ox = viewRect.minX
        let oy = viewRect.minY

        return ZStack {
            ForEach(Array(layout.layers.enumerated()), id: \.offset) { _, layer in
                if config.soundMap[layer.name] != nil {
                    let w = CGFloat(layer.width) * scaleX
                    let h = CGFloat(layer.height) * scaleY
                    let cx = ox + CGFloat(layer.x) * scaleX + w / 2
                    let cy = oy + CGFloat(layer.y) * scaleY + h / 2
                    TappableLayerArea(
                        layerName: layer.name,
                        width: w,
                        height: h,
                        centerX: cx,
                        centerY: cy,
                        activeLayers: $activeLayers,
                        onTap: {
                            audioManager.playEffect(forLayer: layer.name, config: config)
                            triggerScaleAnimation(for: layer.name)
                        }
                    )
                }
            }
        }
    }

    private func triggerScaleAnimation(for layerName: String) {
        withAnimation(.easeInOut(duration: 0.1)) {
            activeLayers = activeLayers.union([layerName])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeLayers = activeLayers.subtracting([layerName])
            }
        }
    }

    // MARK: - Bottom controls

    private var bottomControlBar: some View {
        HStack {
            HStack(spacing: 16) {
                Button {
                    showMusicArchive = true
                } label: {
                    Color.clear
                        .frame(width: 120, height: 120)
                        .handDrawnBorder(cornerRadius: 8, lineWidth: 6)
                        .overlay(
                            Group {
                                if let image = UIImage(named: "Icona_traccia") {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 56, height: 56)
                                } else {
                                    Image(systemName: "music.note.list")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 56, height: 56)
                                        .foregroundColor(.black)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)

                Button {
                    audioManager.toggleBase()
                } label: {
                    Color.clear
                        .frame(width: 120, height: 120)
                        .handDrawnBorder(cornerRadius: 8, lineWidth: 6)
                        .overlay(
                            Group {
                                if audioManager.isBasePlaying {
                                    if let image = UIImage(named: "Icona_pausa") {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                    } else {
                                        Image(systemName: "pause.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                            .foregroundColor(.black)
                                    }
                                } else {
                                    if let image = UIImage(named: "Icona_play") {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                    } else {
                                        Image(systemName: "play.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Color.clear
                    .frame(width: 120, height: 120)
                    .handDrawnBorder(cornerRadius: 8, lineWidth: 6)
                    .overlay(
                        Group {
                            if let image = UIImage(named: "Icona_card") {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                            } else {
                                Image(systemName: "house.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                                    .foregroundColor(.black)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Tappable layer area (tap + hover)

private struct TappableLayerArea: View {
    let layerName: String
    let width: CGFloat
    let height: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
    @Binding var activeLayers: Set<String>
    let onTap: () -> Void

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .position(x: centerX, y: centerY)
            .onTapGesture { onTap() }
            .onHover { hovering in
                if hovering {
                    activeLayers = activeLayers.union([layerName])
                } else {
                    activeLayers = activeLayers.subtracting([layerName])
                }
            }
    }
}

// MARK: - Layered portrait view

private struct PortraitLayeredView: View {
    let layout: PortraitLayoutConfig
    let viewSize: CGSize
    let activeLayers: Set<String>

    private var scaleX: CGFloat { viewSize.width / CGFloat(layout.canvasWidth) }
    private var scaleY: CGFloat { viewSize.height / CGFloat(layout.canvasHeight) }

    var body: some View {
        ZStack {
            ForEach(Array(layout.layers.enumerated()), id: \.offset) { _, layer in
                layerView(layer)
            }
        }
        .frame(width: viewSize.width, height: viewSize.height)
    }

    @ViewBuilder
    private func layerView(_ layer: PortraitLayerLayout) -> some View {
        let w = CGFloat(layer.width) * scaleX
        let h = CGFloat(layer.height) * scaleY
        let centerX = (CGFloat(layer.x) + CGFloat(layer.width) / 2) * scaleX
        let centerY = (CGFloat(layer.y) + CGFloat(layer.height) / 2) * scaleY
        let isActive = activeLayers.contains(layer.name)

        if let image = UIImage(named: layer.name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)
                .scaleEffect(isActive ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isActive)
                .position(x: centerX, y: centerY)
        }
    }
}
