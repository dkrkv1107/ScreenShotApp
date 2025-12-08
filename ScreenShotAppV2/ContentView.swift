import SwiftUI

struct ContentView: View {
    let takeScreenshot: () -> Void
    let takeSelection: () -> Void
    let quitApp: () -> Void
    var feedbackMessage: String = ""
    var isError: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Mini Toast Feedback (only show this)
            if !feedbackMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isError ? .red : .green)
                    Text(feedbackMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isError ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
            } else {
                // Main buttons
                Text("Screenshot Clipboard")
                    .font(.headline)
                
                Button(action: {
                    isPressed = true
                    takeScreenshot()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPressed = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "macwindow")
                        Text("Full Screen")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .opacity(isPressed ? 0.7 : 1.0)
                
                Button(action: {
                    isPressed = true
                    takeSelection()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPressed = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.dashed")
                        Text("Selection")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .opacity(isPressed ? 0.7 : 1.0)
                
                Divider()
                
                Text("Paste anywhere with Cmd+V")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                Button(action: quitApp) {
                    HStack(spacing: 8) {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: 280)
    }
}
