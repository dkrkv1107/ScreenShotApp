import SwiftUI

struct ContentView: View {
    let takeScreenshot: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Screenshot Clipboard")
                .font(.headline)
            
            Button("📸 Capture Screen") {
                takeScreenshot()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("⌥ Capture Selection") {
                // Cmd+Shift+4 style - user selects area
                let task = Process()
                task.launchPath = "/usr/sbin/screencapture"
                task.arguments = ["-i", "-c"]  // Interactive to clipboard
                task.launch()
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            Text("Paste anywhere with Cmd+V")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 220)
    }
}
