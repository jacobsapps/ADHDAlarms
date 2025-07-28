import SwiftUI
import AVFoundation

struct SoundSelectionSection: View {
    @Binding var selectedSound: String?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var currentlyPlayingSound: String?
    
    private let soundOptions: [(filename: String?, label: String)] = [
        (nil, "Default"),
        ("airhorn", "MLG Airhorn"),
        ("2sad4me", "2sad4me"),
        ("wrongnumber", "Wrong Number")
    ]
    
    var body: some View {
        Section(header: Text("Sound")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(soundOptions, id: \.filename) { option in
                        SoundButton(
                            filename: option.filename,
                            label: option.label,
                            isSelected: selectedSound == option.filename,
                            isPlaying: currentlyPlayingSound == (option.filename ?? "default"),
                            onTap: {
                                handleSoundTap(for: option.filename)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func handleSoundTap(for filename: String?) {
        // Always select this sound
        selectedSound = filename
        
        // Handle playback
        let playbackFilename = filename ?? "default" // Use default.mp3 for Default option
        
        if currentlyPlayingSound == playbackFilename {
            // If this sound is playing, pause it
            stopPlayback()
        } else {
            // Stop any other sound and play this one
            stopPlayback()
            playSound(playbackFilename)
        }
    }
    
    private func playSound(_ filename: String) {
        print("🎵 Attempting to play sound: \(filename)")
        
        guard let soundURL = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("❌ Could not find sound file: \(filename).mp3")
            return
        }
        
        print("✅ Found sound file at: \(soundURL)")
        
        do {
            // Set up audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = AudioPlayerDelegate {
                DispatchQueue.main.async {
                    currentlyPlayingSound = nil
                }
            }
            
            
            let success = audioPlayer?.play() ?? false
            if success {
                currentlyPlayingSound = filename
                print("✅ Started playing: \(filename)")
            } else {
                print("❌ Failed to start playback")
            }
        } catch {
            print("❌ Error playing sound: \(error)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentlyPlayingSound = nil
    }
}

struct SoundButton: View {
    let filename: String?
    let label: String
    let isSelected: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Label
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Play/Pause icon (show for all sounds)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .frame(height: 24)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Helper class to handle AVAudioPlayer delegate
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🎵 Audio playback finished successfully: \(flag)")
        onFinish()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Audio decode error: \(error?.localizedDescription ?? "Unknown")")
        onFinish()
    }
}
