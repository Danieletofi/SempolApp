import SwiftUI
import UIKit

// MARK: - Portrait layout (canvas 1024×1366, layer bounds from Figma/config)

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

/// Main play screen for the Elf portrait (Sampol/card-play/Elfo).
struct ElfPlayView: View {
    @StateObject private var audioManager = AudioManager.shared
    @Environment(\.dismiss) private var dismiss

    private static let loadedLayout: PortraitLayoutConfig? = Self.loadPortraitLayout()

    @State private var activeLayers: Set<String> = []

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            // Portrait fills entire screen; controller overlays bottom
            GeometryReader { geometry in
                let viewRect = Self.portraitViewRect(in: geometry.size, layout: Self.loadedLayout)
                ZStack {
                    if let layout = Self.loadedLayout {
                        PortraitLayeredView(layout: layout, viewSize: viewRect.size, activeLayers: activeLayers)
                            .frame(width: viewRect.width, height: viewRect.height)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        tappableAreasFromLayout(layout: layout, viewRect: viewRect)
                    } else {
                        portraitBackgroundFallback
                        tappableAreasFallback(in: geometry.size)
                    }
                }
            }

            // Controller bar overlaid at bottom (Z-elevated, like Figma y=1166/1366)
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
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Load layout JSON

    private static func loadPortraitLayout() -> PortraitLayoutConfig? {
        guard let url = Bundle.main.url(forResource: "PortraitLayout", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PortraitLayoutConfig.self, from: data)
    }

    /// Portrait area rect (origin + size) that fits in `size` with canvas aspect ratio.
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

    // MARK: - Fallback portrait (no layout JSON)

    private var portraitBackgroundFallback: some View {
        ZStack {
            portraitLayerImage("card_1_sfondo")
            portraitLayerImage("card_1_capelli")
            portraitLayerImage("card_1_orecchio_sx")
            portraitLayerImage("card_1_orecchio_dx")
            portraitLayerImage("card_1_occhio_sx")
            portraitLayerImage("card_1_occhio_dx")
            portraitLayerImage("card_1_naso")
            portraitLayerImage("card_1_bocca")
        }
        .aspectRatio(1024 / 1366, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func portraitLayerImage(_ name: String) -> some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Tappable areas from layout (canvas coordinates scaled to view)

    private func tappableAreasFromLayout(layout: PortraitLayoutConfig, viewRect: CGRect) -> some View {
        let scaleX = viewRect.width / layout.canvasWidth
        let scaleY = viewRect.height / layout.canvasHeight
        let ox = viewRect.minX
        let oy = viewRect.minY

        return ZStack {
            ForEach(Array(layout.layers.enumerated()), id: \.offset) { _, layer in
                if let sound = Self.sound(forLayerName: layer.name) {
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
                            audioManager.playEffect(sound)
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

    private static func sound(forLayerName name: String) -> ElfSound? {
        switch name {
        case "card_1_capelli": return .capelli
        case "card_1_orecchio_sx": return .orecchioSinistro
        case "card_1_orecchio_dx": return .orecchioDestro
        case "card_1_occhio_sx": return .occhioSinistro
        case "card_1_occhio_dx": return .occhioDestro
        case "card_1_naso": return .naso
        case "card_1_bocca": return .bocca
        default: return nil
        }
    }

    // MARK: - Fallback tappable areas (factor-based)

    private func tappableAreasFallback(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height
        return ZStack {
            tappableAreaRect(width: width, height: height, widthFactor: 0.75, heightFactor: 0.40, centerXFactor: 0.5, centerYFactor: 0.23, sound: .capelli)
            tappableAreaRect(width: width, height: height, widthFactor: 0.14, heightFactor: 0.22, centerXFactor: 0.18, centerYFactor: 0.45, sound: .orecchioSinistro)
            tappableAreaRect(width: width, height: height, widthFactor: 0.14, heightFactor: 0.23, centerXFactor: 0.82, centerYFactor: 0.45, sound: .orecchioDestro)
            tappableAreaRect(width: width, height: height, widthFactor: 0.10, heightFactor: 0.12, centerXFactor: 0.37, centerYFactor: 0.40, sound: .occhioSinistro)
            tappableAreaRect(width: width, height: height, widthFactor: 0.10, heightFactor: 0.12, centerXFactor: 0.63, centerYFactor: 0.40, sound: .occhioDestro)
            tappableAreaRect(width: width, height: height, widthFactor: 0.13, heightFactor: 0.18, centerXFactor: 0.50, centerYFactor: 0.49, sound: .naso)
            tappableAreaRect(width: width, height: height, widthFactor: 0.45, heightFactor: 0.14, centerXFactor: 0.50, centerYFactor: 0.63, sound: .bocca)
        }
    }

    private func tappableAreaRect(width: CGFloat, height: CGFloat, widthFactor: CGFloat, heightFactor: CGFloat, centerXFactor: CGFloat, centerYFactor: CGFloat, sound: ElfSound) -> some View {
        let w = width * widthFactor
        let h = height * heightFactor
        let x = width * centerXFactor
        let y = height * centerYFactor
        return Rectangle()
            .fill(Color.clear)
            .frame(width: w, height: h)
            .contentShape(Rectangle())
            .position(x: x, y: y)
            .onTapGesture { audioManager.playEffect(sound) }
    }

    // MARK: - Bottom controls

    private var bottomControlBar: some View {
        HStack {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.black, lineWidth: 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white)
                    )
                    .frame(width: 120, height: 120)
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

                Button {
                    audioManager.toggleBase()
                } label: {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.black, lineWidth: 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white)
                        )
                        .frame(width: 120, height: 120)
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.black, lineWidth: 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white)
                    )
                    .frame(width: 120, height: 120)
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

// MARK: - Layered portrait view (each layer drawn in its canvas rect)

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

struct ElfPlayView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ElfPlayView()
        }
        .previewInterfaceOrientation(.portrait)
    }
}
