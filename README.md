# ScreenShotAppV2

This repository contains a macOS SwiftUI Xcode project. The app is in the `ScreenShotAppV2` folder and can be opened and run in Xcode.

## Prerequisites

- macOS with a recent version of Xcode (Xcode 14+ recommended).
- Git (installed on macOS by default). Check with `git --version`.
- Optional: Homebrew and GitHub CLI (`gh`) if you want to work with GitHub from the terminal.

## Clone and open

Clone the repository and open the Xcode project:

```bash
git clone https://github.com/dkrkv1107/ScreenShotApp.git
cd ScreenShotAppV2
# Open the project in Xcode latest version
open ScreenShotAppV2.xcodeproj in Xcode
```

Note: There is an `.xcodeproj` inside the repository. If you see a workspace (`.xcworkspace`) and you're using CocoaPods or SwiftPM workspaces, open the workspace instead.

## Build & run (Xcode)

1. Open the project in Xcode.
2. Select the macOS target (the app target) in the toolbar.
3. Click the Run ▶ button or press ⌘R.

If Xcode prompts for signing or provisioning, adjust the signing settings in the project target (for development you can use your personal team).

## macOS privacy permissions

Because this app interacts with screenshots / screen content, macOS may require the app to have Screen Recording permissions. If the app requests it, grant permission in:

System Settings → Privacy & Security → Screen Recording

You may need to quit and re-launch the app after granting permission.
