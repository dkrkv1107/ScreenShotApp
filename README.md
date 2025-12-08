# ScreenShotAppV2

This repository contains a macOS SwiftUI Xcode project. The app is in the `ScreenShotAppV2` folder and can be opened and run in Xcode.

## Repository

Remote: https://github.com/dkrkv1107/ScreenShotApp

## Prerequisites

- macOS with a recent version of Xcode (Xcode 14+ recommended).
- Git (installed on macOS by default). Check with `git --version`.
- Optional: Homebrew and GitHub CLI (`gh`) if you want to work with GitHub from the terminal.

## Clone and open

Clone the repository and open the Xcode project:

```bash
git clone https://github.com/dkrkv1107/ScreenShotApp.git
cd ScreenShotAppV2
# Open the project in Xcode
open ScreenShotAppV2.xcodeproj
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

## Command-line build (optional)

You can build from the command-line using `xcodebuild`, but it's easiest to use Xcode for development.

Example (basic):

```bash
# From repo root
xcodebuild -project ScreenShotAppV2.xcodeproj -scheme <SchemeName> -configuration Debug
```

Replace `<SchemeName>` with the actual scheme shown in Xcode.

## Git workflow (recommended)

- Create a feature branch for new work:

```bash
git checkout -b feature/your-feature
```

- Stage and commit changes:

```bash
git add .
git commit -m "Describe your change"
```

- Push the branch and open a Pull Request on GitHub:

```bash
git push -u origin feature/your-feature
```

Then open the repository on GitHub and create a Pull Request.

## .gitignore recommendation

This project currently contains some user-specific Xcode files that should be ignored. Add a `.gitignore` with at least the following entries to avoid committing local user state and build artifacts:

```
# Xcode
*.xcuserstate
xcuserdata/
DerivedData/
*.xcworkspace/xcuserdata/

# Swift Package Manager
.build/

# macOS
*.DS_Store
```

If you want I can add a `.gitignore` file for you and commit it.

## Contributing

- Please open issues or submit Pull Requests.
- Keep changes focused and include a short description in each PR.

## Troubleshooting

- If Xcode warns about missing signing identities, set a Development Team in the target Signing & Capabilities.
- If the app can't capture the screen, verify System Settings → Privacy & Security → Screen Recording for the app.

## License

Add a license file if you want to make the project's license explicit (e.g., `LICENSE` with MIT/Apache/etc.).

---

If you want any of the following, tell me and I will add them now:
- Add and commit a `.gitignore` (recommended).
- Switch remote to SSH URL `git@github.com:dkrkv1107/ScreenShotApp.git`.
- Add a `LICENSE` file.
# ScreenShotApp