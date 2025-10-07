import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL?
    @State private var showFullscreen = false
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let url = videoURL {
                ZStack {
                    // Thumbnail/placeholder with play button
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.2))
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)

                                Text("Tap to watch setup guide")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        )
                        .aspectRatio(9/16, contentMode: .fit) // Phone aspect ratio
                        .onTapGesture {
                            showFullscreen = true
                            player = AVPlayer(url: url)
                        }
                }
                .fullScreenCover(isPresented: $showFullscreen, onDismiss: {
                    player?.pause()
                    player = nil
                }) {
                    if let player = player {
                        VideoPlayer(player: player)
                            .ignoresSafeArea()
                            .onAppear {
                                player.play()
                            }
                    }
                }
            } else {
                // Placeholder when no video
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(9/16, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("Video coming soon")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
    }
}

#Preview {
    VideoPlayerView(videoURL: nil)
        .padding()
}
