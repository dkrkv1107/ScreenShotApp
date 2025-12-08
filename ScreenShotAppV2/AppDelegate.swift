import Cocoa
import SwiftUI
import CoreGraphics
import ScreenCaptureKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        // Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "Screenshot")
        statusItem?.button?.action = #selector(togglePopover)
        
        // Popover with screenshot buttons
        popover.behavior = .transient
        popover.animates = true
        let contentView = ContentView { [weak self] in
            Task { await self?.takeScreenshot() }
        }
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    @MainActor
    private func takeScreenshot() async {
        do {
            // Fetch shareable content to get available displays
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else {
                print("No displays available for capture.")
                return
            }

            // Create a filter to capture only the selected display
            let filter = SCContentFilter(display: display, excludingWindows: [])

            // Configure a low-latency, single-frame stream
            let config = SCStreamConfiguration()
            config.capturesAudio = false
            config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            config.queueDepth = 1
            config.width = display.width
            config.height = display.height

            // Set up a stream that we can pull a single frame from
            let stream = SCStream(filter: filter, configuration: config, delegate: nil)

            // A helper class to receive frames
            final class FrameReceiver: NSObject, SCStreamOutput {
                var image: CGImage?
                let semaphore = DispatchSemaphore(value: 0)
                private let ciContext = CIContext()

                func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
                    guard outputType == .screen else { return }
                    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                    if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                        image = cgImage
                        semaphore.signal()
                    }
                }
            }

            let receiver = FrameReceiver()
            let outputQueue = DispatchQueue(label: "screen.capture.output")
            try stream.addStreamOutput(receiver, type: .screen, sampleHandlerQueue: outputQueue)
            try await stream.startCapture()

            // Wait briefly for the first frame
            _ = receiver.semaphore.wait(timeout: .now() + 1.0)

            // Stop capture as soon as we have a frame (or timed out)
            stream.stopCapture { _ in }

            guard let cgImage = receiver.image else {
                print("Failed to capture screen frame.")
                return
            }

            // Convert to NSImage/PNG and copy to clipboard
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            let nsImage = NSImage(size: NSSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh))
            nsImage.addRepresentation(bitmapRep)

            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                print("Failed to create PNG data from screenshot.")
                return
            }

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setData(pngData, forType: .png)
            print("Screenshot copied to clipboard!")
        } catch {
            print("Screen capture failed: \(error)")
        }
    }
}
