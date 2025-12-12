import Cocoa
import SwiftUI
import CoreServices

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var contentViewController: ScreenshotContentController?
    
    private var fileSystemWatcher: FileSystemWatcher?
    private var lastScreenshotTime: Date = Date()
    private var pollingTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        
        print("📁 Monitoring for screenshots at:")
        print("   Desktop: /Users/neerajkumarrai/Desktop")
        print("   Pictures: \(NSHomeDirectory())/Pictures")
        
        setupStatusBar()
        setupScreenshotMonitoring()
    }
    
    // MARK: - Menu bar / popover
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "photo.on.rectangle",
                accessibilityDescription: "Screenshot Clipboard"
            )
            button.action = #selector(togglePopover)
        }
        
        popover.behavior = .transient
        popover.animates = true
        
        contentViewController = ScreenshotContentController(appDelegate: self)
        popover.contentViewController = contentViewController
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    // MARK: - Monitor Cmd+Shift+3/4 screenshots
    
    private func setupScreenshotMonitoring() {
        fileSystemWatcher = FileSystemWatcher(paths: [NSHomeDirectory() + "/Desktop"]) { [weak self] in
            print("🔔 FSEvents triggered")
            self?.checkForNewScreenshot()
        }
        fileSystemWatcher?.start()
        
        // Polling backup (every 0.5 seconds)
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForNewScreenshot()
        }
    }
    
    private func checkForNewScreenshot() {
        let desktopFolder = NSHomeDirectory() + "/Desktop"
        let picturesFolder = NSHomeDirectory() + "/Pictures"
        
        for folder in [desktopFolder, picturesFolder] {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: folder) else {
                continue
            }
            
            let screenshotFiles = files
                .filter { $0.hasPrefix("Screenshot") && $0.hasSuffix(".png") }
                .sorted()
            
            guard let latestFile = screenshotFiles.last else { continue }
            
            let fullPath = (folder as NSString).appendingPathComponent(latestFile)
            
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let modDate = attributes[.modificationDate] as? Date {
                
                let timeSinceLastScreenshot = Date().timeIntervalSince(lastScreenshotTime)
                let timeSinceFileModified = Date().timeIntervalSince(modDate)
                
                print("📸 Found: \(latestFile)")
                print("   Modified: \(String(format: "%.2f", timeSinceFileModified))s ago")
                print("   Last processed: \(String(format: "%.2f", timeSinceLastScreenshot))s ago")
                
                if timeSinceFileModified < 2.0 && timeSinceLastScreenshot > 1.0 {
                    print("✅ Processing new screenshot: \(latestFile)")
                    lastScreenshotTime = Date()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.copyScreenshotToClipboard(fullPath)
                    }
                    return
                }
            }
        }
    }
    
    private func copyScreenshotToClipboard(_ filePath: String) {
        do {
            let url = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: url)
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setData(data, forType: .png)
            
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            
            print("✅ Copied to clipboard: \(filePath)")
            
            if popover.isShown {
                contentViewController?.setFeedback("✓ Screenshot copied!", isError: false)
                showPopoverWithFeedback()
            }
        } catch {
            print("❌ Failed to copy screenshot: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Actions from popover buttons
    
    func takeFullScreenshot() {
        popover.performClose(nil)
        
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-c"]
        
        task.terminationHandler = { [weak self] process in
            guard let self = self else { return }
            
            if process.terminationStatus == 0 {
                DispatchQueue.main.async {
                    self.contentViewController?.setFeedback("✓ Screenshot copied!", isError: false)
                    self.showPopoverWithFeedback()
                }
            } else {
                DispatchQueue.main.async {
                    self.contentViewController?.setFeedback("✗ Capture failed!", isError: true)
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
    
    func takeSelectionScreenshot() {
        popover.performClose(nil)
        
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        
        task.terminationHandler = { [weak self] process in
            guard let self = self else { return }
            
            if process.terminationStatus == 0 {
                DispatchQueue.main.async {
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
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
    
    func showPopoverWithFeedback() {
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.popover.performClose(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.contentViewController?.resetFeedback()
            }
        }
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
}

// MARK: - File System Watcher

class FileSystemWatcher {
    private var stream: FSEventStreamRef?
    let callback: () -> Void
    let paths: [String]
    
    init(paths: [String], callback: @escaping () -> Void) {
        self.paths = paths
        self.callback = callback
    }
    
    func start() {
        let streamContext = UnsafeMutablePointer<FSEventStreamContext>.allocate(capacity: 1)
        streamContext.pointee = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: FSEventStreamCallback = { stream, contextInfo, numEvents, eventPaths, eventFlags, eventIds in
            guard let contextInfo = contextInfo else { return }
            let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(contextInfo).takeUnretainedValue()
            watcher.callback()
        }
        
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            streamContext,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
        )
        
        if let stream = stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }
    
    deinit {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}

// MARK: - Content Controller

class ScreenshotContentController: NSViewController {
    var appDelegate: AppDelegate?
    var contentView: ContentView?
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        super.init(nibName: nil, bundle: nil)
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
