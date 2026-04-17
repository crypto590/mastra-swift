# iOS Showcase

A streaming chat template for iOS, built on [mastra-swift](../..). Runs on the iOS 26 Simulator out of the box.

## Why we built this

[Mastra](https://mastra.ai) publishes 12+ official templates under `github.com/mastra-ai/template-*` — every one of them is TypeScript. `mastra-swift` added iOS 16+ support to the client SDK, so this template exists to fill the gap: a polished, runnable iOS app you can clone, point at any Mastra server, and have a real conversation with in under ten minutes.

It doubles as a working reference for the three pieces of the SDK that together make a chat app feel native:

- `MastraClient` — the actor-based entry point.
- `agent.stream(GenerateParams)` — token-by-token streaming over the Mastra Data Stream format.
- `createMemoryThread` + `listThreadMessages` — persistent memory threads that survive app launches.

## Features

- **Streaming chat** — tokens arrive over the Mastra Data Stream and render as they decode. Cancel mid-stream with the stop button.
- **Persistent memory** — the first message creates a memory thread; the id is stored in `UserDefaults` and attached to every subsequent request. Force-quit the app and your conversation is still there on relaunch.
- **History rehydration** — on launch with an existing thread, messages are loaded via `client.listThreadMessages(...)`.
- **New conversation** — rotates the stored thread id, leaving the previous thread intact on the server.
- **SwiftUI Previews** — `ChatView` renders in the Xcode canvas with a mocked conversation; no running server required to iterate on UI.
- **Graceful misconfig** — missing env values land on a friendly "Setup needed" screen instead of a crash.
- **Zero external dependencies** — just Foundation + the local `mastra-swift` package.

## Quick start

1. **Stand up a Mastra server.** Any template works:
   ```
   npx create-mastra@latest demo --template deep-research
   cd demo && npm run dev
   ```
   The server will be listening on `http://localhost:4111`.

2. **Configure the app.** From this directory:
   ```
   cp Secrets.xcconfig.example Secrets.xcconfig
   ```
   Open `Secrets.xcconfig` and fill in the three values (`MASTRA_BASE_URL`, `MASTRA_AGENT_ID`, optionally `MASTRA_API_KEY`).

3. **Open the project in Xcode 26+:**
   ```
   open iOSShowcase.xcodeproj
   ```

4. **Build & run.** Pick an iPhone 17 (or any iOS 26) simulator and hit ⌘R. Start chatting.

If you skip step 2, the app still launches — it just shows a "Setup needed" screen pointing you back here.

## Making it yours

- **Swap the agent.** Change `MASTRA_AGENT_ID` in `Secrets.xcconfig`. No code changes.
- **Add client-side tools.** Construct `ClientTool` values and pass them via `GenerateParams(clientTools:)` in `ChatController.swift`.
- **Replace `UserDefaults` with Keychain** for the stored thread id — swap out `UserDefaultsThreadStore` with your own `ThreadStore` implementation.
- **Grow the UI.** Add a sidebar of threads by calling `client.listMemoryThreads(...)`. Add workflow output by calling `client.workflow(id:).createRun()`. The controller pattern generalizes.
- **Ship your own template.** Fork, rename, swap the agent logic and icon, point your users at the new repo. The structure is intentionally minimal.

## Layout

```
iOSShowcase/
├── iOSShowcaseApp.swift        # @main, builds MastraClient, handles config failure
├── AppConfig.swift             # Reads Info.plist → typed config; throws on missing keys
├── MisconfiguredView.swift     # Setup-needed screen
├── Chat/
│   ├── ChatController.swift    # @Observable streaming + memory thread state
│   ├── ChatView.swift          # Message list, composer, toolbar
│   ├── MessageBubble.swift     # Role-styled bubble with typing indicator
│   ├── ChatMessage.swift       # Local view model
│   └── ThreadStore.swift       # Persistence protocol + UserDefaults impl
└── Preview Content/
    └── PreviewClient.swift     # Seeds ChatController for SwiftUI Previews
```

## About mastra-swift templates

This is the iOS counterpart to Mastra's JS template ecosystem. See the repo's [Examples/](..) directory for other samples — `SwiftUIChat` is the minimal SwiftPM link-check version, and `CLIPlayground` exercises the SDK from a macOS command line. If you build a Swift template worth sharing, open a PR.
