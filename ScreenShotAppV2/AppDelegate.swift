import Cocoa
import SwiftUI
import ScreenCaptureKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var contentViewController: ScreenshotContentController?
    
    private let shutterSound = NSSound(named: "Purr")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "Screenshot")
        statusItem?.button?.action = #selector(togglePopover)
        
        popover.behavior = .transient
        popover.animates = true
        
        contentViewController = ScreenshotContentController(appDelegate: self)
        popover.contentViewController = contentViewController
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    func takeFullScreenshot() {
        popover.performClose(nil)

        // Run system screenshot tool: full screen to clipboard, with sound
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-c"]    // full screen, to clipboard, plays system sound

        task.terminationHandler = { [weak self] process in
            guard let self = self else { return }

            // Only show feedback if successful
            if process.terminationStatus == 0 {
                DispatchQueue.main.async {
                    self.contentViewController?.setFeedback("✓ Screenshot copied!", isError: false)
                    self.showPopoverWithFeedback()
                }
            }
        }

        do {
            try task.run()
        } catch {
            DispatchQueue.main.async {
                self.contentViewController?.setFeedback("✗ Capture failed!", isError: true)
                self.showPopoverWithFeedback()
            }
        }
    }

    
    private func captureScreenWithScreenCaptureKit() async {
        do {
            let available = try await SCShareableContent.current
            guard let screen = available.displays.first else {
                DispatchQueue.main.async {
                    self.contentViewController?.setFeedback("✗ No screen found!", isError: true)
                    self.showPopoverWithFeedback()
                }
                return
            }
            
            let contentFilter = SCContentFilter(display: screen, excludingApplications: [], exceptingWindows: [])
            let streamConfig = SCStreamConfiguration()
            streamConfig.width = Int(screen.width)
            streamConfig.height = Int(screen.height)
            streamConfig.showsCursor = false
            
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: contentFilter, configuration: streamConfig)
            let nsImage = NSImage(cgImage: cgImage, size: NSZeroSize)
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setData(nsImage.tiffRepresentation!, forType: .tiff)
            
            shutterSound?.play()
            
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            
            DispatchQueue.main.async {
                self.contentViewController?.setFeedback("✓ Screenshot copied!", isError: false)
                self.showPopoverWithFeedback()
            }
            
            print("Full screenshot copied to clipboard!")
        } catch {
            DispatchQueue.main.async {
                self.contentViewController?.setFeedback("✗ Capture failed!", isError: true)
                self.showPopoverWithFeedback()
            }
            print("Failed to capture screenshot: \(error.localizedDescription)")
        }
    }
    
    func takeSelectionScreenshot() {
        // Hide popover
        popover.performClose(nil)
        
        // Use system screencapture tool for interactive selection
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]  // Interactive to clipboard
        
        // When the user finishes (or cancels), this gets called
        task.terminationHandler = { [weak self] process in
            guard let self = self else { return }
            
            // If user cancelled, exit status is usually non‑zero; skip feedback
            if process.terminationStatus == 0 {
                DispatchQueue.main.async {
                    NSHapticFeedbackManager.defaultPerformer.perform(
                        .generic,
                        performanceTime: .now
                    )
                    self.contentViewController?.setFeedback("✓ Selection copied!", isError: false)
                    self.showPopoverWithFeedback()
                }
            }
        }
        
        do {
            try task.run()
        } catch {
            DispatchQueue.main.async {
                self.contentViewController?.setFeedback("✗ Capture failed!", isError: true)
                self.showPopoverWithFeedback()
            }
        }
    }

    private func showPopoverWithFeedback() {
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        
        // Auto-dismiss and reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.popover.performClose(nil)
            // Reset feedback state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.contentViewController?.resetFeedback()
            }
        }
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// Separate controller to manage state
class ScreenshotContentController: NSViewController {
    var appDelegate: AppDelegate?
    var contentView: ContentView?
    
    init(appDelegate: AppDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.appDelegate = appDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        contentView = ContentView(
            takeScreenshot: { self.appDelegate?.takeFullScreenshot() },
            takeSelection: { self.appDelegate?.takeSelectionScreenshot() },
            quitApp: { self.appDelegate?.quitApp() },
            feedbackMessage: "",
            isError: false
        )
        view = NSHostingView(rootView: contentView!)
    }
    
    func setFeedback(_ message: String, isError: Bool) {
        contentView = ContentView(
            takeScreenshot: { self.appDelegate?.takeFullScreenshot() },
            takeSelection: { self.appDelegate?.takeSelectionScreenshot() },
            quitApp: { self.appDelegate?.quitApp() },
            feedbackMessage: message,
            isError: isError
        )
        view = NSHostingView(rootView: contentView!)
    }
    
    func resetFeedback() {
        contentView = ContentView(
            takeScreenshot: { self.appDelegate?.takeFullScreenshot() },
            takeSelection: { self.appDelegate?.takeSelectionScreenshot() },
            quitApp: { self.appDelegate?.quitApp() },
            feedbackMessage: "",
            isError: false
        )
        view = NSHostingView(rootView: contentView!)
    }
}
