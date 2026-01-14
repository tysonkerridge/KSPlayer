//
//  KSVideoPlayerViewBuilder.swift
//
//
//  Created by Ian Magallan Bosch on 17.03.24.
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
enum KSVideoPlayerViewBuilder {
    @MainActor
    static func playbackControlView(config: KSVideoPlayer.Coordinator, spacing: CGFloat? = nil) -> some View {
        HStack(spacing: spacing) {
            // Playback controls don't need spacers for visionOS, since the controls are laid out in a HStack.
            #if os(xrOS)
            backwardButton(config: config)
            playButton(config: config)
            forwardButton(config: config)
            #else
            if #available(iOS 26.0, *) {
                Spacer()
                GlassEffectContainer(spacing: spacing) {
                    HStack(spacing: -10) {
                        backwardButton(config: config)
                            .opacity(config.isMaskShow ? 1.0 : 0)
                            .offset(x: config.isMaskShow ? 0 : 50)
                            .animation(.easeInOut(duration: 0.25), value: config.isMaskShow)
                        playButton(config: config)
                        forwardButton(config: config)
                            .opacity(config.isMaskShow ? 1.0 : 0)
                            .offset(x: config.isMaskShow ? 0 : -50)
                            .animation(.easeInOut(duration: 0.25), value: config.isMaskShow)
                    }
                }
                Spacer()
            } else {
                // Fallback on earlier versions
                Spacer()
                backwardButton(config: config)
                Spacer()
                playButton(config: config)
                Spacer()
                forwardButton(config: config)
                Spacer()
            }
            #endif
        }
    }

    @MainActor
    static func contentModeButton(config: KSVideoPlayer.Coordinator) -> some View {
        Button {
            config.isScaleAspectFill.toggle()
        } label: {
            Image(systemName: config.isScaleAspectFill ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                .foregroundColor(.white)
                .fontWeight(.bold)
                .font(.title2)
        }
    }

    @MainActor
    static func subtitleButton(config: KSVideoPlayer.Coordinator) -> some View {
        MenuView(selection: Binding {
            config.subtitleModel.selectedSubtitleInfo?.subtitleID
        } set: { value in
            let info = config.subtitleModel.subtitleInfos.first { $0.subtitleID == value }
            config.subtitleModel.selectedSubtitleInfo = info
            if let info = info as? MediaPlayerTrack {
                // 因为图片字幕想要实时的显示，那就需要seek。所以需要走select track
                config.playerLayer?.player.select(track: info)
            }
        }) {
            Text("Off").tag(nil as String?)
            ForEach(config.subtitleModel.subtitleInfos, id: \.subtitleID) { track in
                Text(track.display).tag(track.subtitleID as String?)
            }
        } label: {
            Image(systemName: "text.bubble")
#if os(tvOS)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
#else
                .foregroundColor(.white)
                .fontWeight(.bold)
                .font(.title2)
#endif
        }
    }

    @MainActor
    static func playbackRateButton(playbackRate: Binding<Float>) -> some View {
        MenuView(selection: playbackRate) {
            ForEach([0.5, 1.0, 1.25, 1.5, 2.0] as [Float]) { value in
                // 需要有一个变量text。不然会自动帮忙加很多0
                let text = "\(value) x"
                Text(text).tag(value)
            }
        } label: {
            Image(systemName: "gauge.with.dots.needle.67percent")
#if os(tvOS)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
#else
                .foregroundColor(.white)
                .fontWeight(.bold)
                .font(.title2)
#endif
        }
    }

    @MainActor
    static func titleView(title: String, config: KSVideoPlayer.Coordinator) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 5, x: 0, y: 0)
        }
    }
    
    @MainActor
    static func subtitleView(title: String, config: KSVideoPlayer.Coordinator) -> some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundColor(.gray)
                .shadow(color: .black, radius: 5, x: 0, y: 0)
        }
    }

    @MainActor
    static func muteButton(config: KSVideoPlayer.Coordinator) -> some View {
        Button {
            config.isMuted.toggle()
        } label: {
            Image(systemName: config.isMuted ? speakerDisabledSystemName : speakerSystemName)
#if os(tvOS)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
#else
                .foregroundColor(.white)
                .fontWeight(.bold)
                .font(.title2)
#endif
        }
        .padding(12)
        .KSGlassEffect()
    }

    static func infoButton(showVideoSetting: Binding<Bool>) -> some View {
        Button {
            showVideoSetting.wrappedValue.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
#if os(tvOS)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
#else
                .foregroundColor(.white)
                .fontWeight(.bold)
                .font(.title2)
#endif
        }
        // iOS 模拟器加keyboardShortcut会导致KSVideoPlayer.Coordinator无法释放。真机不会有这个问题
        #if !os(tvOS)
        .keyboardShortcut("i", modifiers: [.command])
        #endif
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension KSVideoPlayerViewBuilder {
    static var playSystemName: String {
        "play.fill"
    }

    static var pauseSystemName: String {
        "pause.fill"
    }

    static var speakerSystemName: String {
        #if os(xrOS)
        "speaker.fill"
        #else
        "speaker.wave.2.fill"
        #endif
    }

    static var speakerDisabledSystemName: String {
        "speaker.slash.fill"
    }

    @MainActor
    @ViewBuilder
    static func backwardButton(config: KSVideoPlayer.Coordinator) -> some View {
        if config.playerLayer?.player.seekable ?? false {
            Button {
                config.skip(interval: -15)
            } label: {
                Image(systemName: "gobackward.15")
                .resizable()
                .frame(width: 25, height: 25, alignment: .center)
                .foregroundColor(.white)
                .padding(10)
            }
            .KSGlassEffect()
            #if !os(tvOS)
            .keyboardShortcut(.leftArrow, modifiers: .none)
            #endif
        }
    }

    @MainActor
    @ViewBuilder
    static func forwardButton(config: KSVideoPlayer.Coordinator) -> some View {
        if config.playerLayer?.player.seekable ?? false {
            Button {
                config.skip(interval: 15)
            } label: {
                Image(systemName: "goforward.15")
                .resizable()
                .frame(width: 25, height: 25, alignment: .center)
                .foregroundColor(.white)
                .padding(10)
            }
            .KSGlassEffect()
            #if !os(tvOS)
            .keyboardShortcut(.rightArrow, modifiers: .none)
            #endif
        }
    }

    @MainActor
    static func playButton(config: KSVideoPlayer.Coordinator) -> some View {
        Button {
            if config.state.isPlaying {
                config.playerLayer?.pause()
            } else {
                config.playerLayer?.play()
            }
        } label: {
            if [KSPlayerState.buffering, .initialized, .preparing, .readyToPlay].contains(config.state) {
                ProgressView()
                .controlSize(.regular)
                .frame(width: 40, height: 40, alignment: .center)
                .foregroundColor(.white)
                .padding(20)
            } else {
                Image(systemName: config.state == .error ? "play.slash.fill" : (config.state.isPlaying ? pauseSystemName : playSystemName))
                    .resizable()
                    .frame(width: 40, height: 40, alignment: .center)
                    .foregroundColor(.white)
                    .padding(20)
            }
        }
        .KSGlassEffect()
        
        #if os(xrOS)
        .contentTransition(.symbolEffect(.replace))
        #endif
        #if !os(tvOS)
        .keyboardShortcut(.space, modifiers: .none)
        #endif
    }
}
