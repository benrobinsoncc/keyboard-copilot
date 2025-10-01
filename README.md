# Keyboard Copilot

Keyboard Copilot is an AI-forward iOS custom keyboard with a lightweight host app. The initial milestone wires up the host application and a keyboard extension that exposes stubbed "✨ Write" and "🔍 Search" actions. These placeholders will evolve into network-backed AI responses in future iterations.

## Project Structure

```
Keyboard Copilot
├── App
│   ├── Resources
│   │   └── Info.plist
│   └── Sources
│       ├── AppDelegate.swift
│       ├── HostViewController.swift
│       └── SceneDelegate.swift
├── KeyboardExtension
│   ├── Resources
│   │   └── Info.plist
│   └── Sources
│       └── KeyboardViewController.swift
├── Shared
│   └── Sources
│       └── KeyboardActionHandler.swift
└── Keyboard Copilot.xcodeproj
```

- **Host app**: Presents a minimal landing screen today; will host onboarding and subscription flows later.
- **Keyboard extension**: Implements the input view controller, text area, and toolbar buttons. Actions route through `KeyboardActionHandler` so we can plug in AI services without modifying the UI layer.

## Building & Running

1. Open `Keyboard Copilot.xcodeproj` in Xcode (15+).
2. Select a simulator destination (e.g. iPhone 16 Pro).
3. In Signing & Capabilities for both targets, choose your Apple ID/team. Adjust bundle identifiers if they collide with existing apps.
4. Build & run the `Keyboard Copilot` scheme once to install the app and extension.
5. In the simulator: `Settings → General → Keyboard → Keyboards → Add New Keyboard...` and choose **Keyboard Copilot**. Leave **Allow Full Access** off for now.
6. Open an app with a text field (Notes, Messages). Switch keyboards with the 🌐 key until **Keyboard Copilot** shows. Tapping "✨ Write" or "🔍 Search" inserts placeholder text locally and into the host text field.

## Next Steps (Future Iterations)

- Replace placeholder responses with host-app mediated API integrations (OpenAI, search providers).
- Add onboarding flow in the host app to guide users through enabling the keyboard and managing subscriptions.
- Design modular UI components for future modes (AI answer, image lookup, maps) based on the concept mocks.
- Expand accessibility and localization (dynamic type tweaks, VoiceOver labels, multi-language keyboard attributes).
- Introduce automated UI/unit tests to guard the extension lifecycle and host app flows once logic grows.

## Requirements

- Xcode 15 or later.
- iOS 16.0+ deployment target.

