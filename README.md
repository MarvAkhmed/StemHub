# StemHub

StemHub is a multi-platform collaborative music production app with:
- shared authentication and session management
- a full macOS production workspace (projects, branches, versions, comments, MIDI editing, audio review)
- a focused iOS authenticated experience (workspace summary, inbox, profile, settings)

The codebase is organized around MVVM, SOLID, Repository, and dependency-injected feature modules.

## What The App Does

### Shared (macOS + iOS)
- Email/password sign up, sign in, and reset password.
- Google Sign-In with runtime validation for:
- Firebase configuration presence.
- URL scheme setup.
- Keychain entitlements (macOS).
- Session restore and current user auth state streaming.

### macOS App (Primary Production Surface)
- Workspace home:
- Loads bands and projects for the authenticated user.
- Groups projects by band section.
- Supports project search by name.
- Shows project metadata diff summary (added/modified/removed/renamed counts from latest version).
- New project flow:
- Select local project folder.
- Read folder metadata (audio count, MIDI count, total files, size).
- Select project poster artwork.
- Attach to existing band or create a new band.
- Add co-admins by email.
- Project detail:
- Branching: load branch workspace, switch branch, create branch.
- Version history: browse, select versions, inspect diffs.
- Commit workflow:
- Prepare commit draft from local tree vs remote snapshot.
- Explicit deletion consent required before staging removed files.
- Push local commits to create remote versions.
- Pull latest branch state to local folder.
- Collaboration:
- Invite members to band (admin-gated).
- Accept/decline invitations in inbox.
- Add timestamped comments on files/audio.
- Mark comments as accepted/rejected and hide accepted from timeline.
- Approval gate:
- Version approval is admin-gated.
- Audio workflow:
- Import audio into project folder.
- Single-file playback with seek/rate control.
- Multi-stem playback with selective play-all.
- MIDI workflow:
- Navigate to dedicated MIDI editor.
- Load/save MIDI files using Core Audio APIs.
- Real-time CoreMIDI controller monitoring via AsyncStream.
- Record note/control events and edit note/controller data.
- Settings and profile:
- Producer playback/review/notification/export preferences.
- Release-ready candidate list from workspace/version state.

### iOS App (Authenticated Flow)
- Separate authenticated flow after launch/auth.
- Tab-based navigation: Workspace, Inbox, Profile, Settings.
- Workspace summary with featured project and project list.
- Mobile project detail snapshot.
- Invitation inbox with accept/decline.
- Profile with bands and release-ready items.
- Settings persistence (playback/review/notification/export preferences).

## Architecture Overview

StemHub uses a feature-first, layered architecture across targets.

```text
StemHub(Shared)
  LaunchScreen/
    Models/
    ViewModel/
    Views/
    Service/
    Modules/
  Resources/
    Configuration/

StemHub(macOS)
  App/
    Composition/
    Root/
    Support/
  Features/
    Workspace/
      Presentation/
      Application/
      Domain/
      Infrastructure/
    Notifications/
    Profile/
    Settings/
    AppShell/

StemHub(iOS)
  App/
    Composition/
    Navigation/
    Support/
  Features/
    Launch/
    Workspace/
    Inbox/
    Profile/
    Settings/
    Common/
```

### Layered Design Inside Features
- Presentation: SwiftUI views + ViewModels (`@MainActor`, `ObservableObject`).
- Application: services/use-cases that coordinate domain operations.
- Domain: entities, value types, errors, feature contracts.
- Infrastructure: Firebase, local file system, CoreMIDI/CoreAudio, pickers, state stores.

### Primary Architectural Styles Used
- MVVM.
- Layered/Clean-style feature architecture (Presentation, Application, Domain, Infrastructure).
- Repository architecture with protocol-first boundaries.
- Service-oriented use-case layer for business workflows.
- Actor-based concurrency for local mutable state coordination.

## Design Patterns Used

### 1) MVVM
- View state and user intents are encapsulated in ViewModels.
- Views remain declarative and mostly stateless.

Examples:
- `StemHub(macOS)/Features/Workspace/Presentation/ViewModels/Home/WorkspaceViewModel.swift`
- `StemHub(macOS)/Features/Workspace/Presentation/ViewModels/ProjectDetail/ProjectDetailViewModel.swift`
- `StemHub(iOS)/Features/Workspace/Presentation/WorkspaceViewModel.swift`

### 2) Repository Pattern
- Data access is abstracted behind protocols and implemented in Firestore adapters.
- Application/services depend on repository contracts, not Firestore directly.

Examples:
- `StemHub(macOS)/Features/Workspace/Infrastructure/Repositories/Protocols/*.swift`
- `StemHub(macOS)/Features/Workspace/Infrastructure/Repositories/Firestore/*.swift`

### 3) Dependency Injection + Composition Root
- Object graphs are assembled centrally in composition containers/modules.
- Feature services/ViewModels receive dependencies via initializers.

Examples:
- `StemHub(macOS)/App/Composition/WorkspaceDependencyContainer.swift`
- `StemHub(macOS)/App/Composition/WorkspaceServiceContainer.swift`
- `StemHub(macOS)/App/Composition/WorkspaceModule.swift`
- `StemHub(iOS)/App/Composition/IOSAuthenticatedFlowModule.swift`

### 4) Strategy Pattern
- Swappable algorithms/services for scanning, diffing, storage, bookmarks, Firestore strategies.

Examples:
- `SyncOrchestrator` with `FileScanner`, `DiffEngineStrategy`, upload/storage strategies.
- `DefaultFirestoreVersionStrategy`, `DefaultFirestoreBranchStrategy`, `DefaultFirestoreBlobStrategy`.

### 5) Adapter / Mapping Pattern
- Firestore document mapping separated from domain models in iOS and macOS repos.

Examples:
- `StemHub(iOS)/Features/Workspace/Infrastructure/IOSWorkspaceFirestoreMapping.swift`
- `StemHub(iOS)/Features/Inbox/Infrastructure/IOSBandInvitationFirestoreMapping.swift`

### 6) State Pattern (UI/Workflow States)
- Activity enums model async UI workflows and loading overlays deterministically.

Examples:
- `WorkspaceActivityState`
- `ProjectDetailActivityState`
- `AuthActivityState`

### 7) Observer / Reactive State
- `@Published` and (where needed) Combine publishers for auth/session and UI updates.
- AsyncStream used for MIDI event streams.

## SOLID Application In This Codebase

### Single Responsibility Principle (SRP)
- Services are narrowly scoped:
- `ProjectCreationService` handles create flow.
- `ProjectBranchService` handles branch workflows.
- `ProjectCommentService` handles comment operations.
- `ProjectVersionApprovalService` handles approval only.
- `ProjectLocalWorkspaceService` handles local file/commit workspace concerns.

### Open/Closed Principle (OCP)
- Behavior extensions happen by adding new protocol conformers, not rewriting callers.
- Example: repository protocols + multiple concrete strategy/repository implementations.

### Liskov Substitution Principle (LSP)
- ViewModels/services consume protocol contracts (`any Protocol`), allowing substitutable implementations in composition.

### Interface Segregation Principle (ISP)
- Large interfaces were split into granular contracts, then composed:
- `AuthenticatedUserProviding`, `SessionLoggingOut`, etc.
- `UserEmailLookup`, `UserDirectoryReading`, etc.
- `ProjectCreating`, `ProjectDeleting`, `ProjectPosterUpdating`, etc.

### Dependency Inversion Principle (DIP)
- High-level modules depend on abstractions.
- Concrete Firebase/local/system implementations are injected at composition roots.

## Concurrency And Threading Model

StemHub uses Swift Concurrency to keep UI responsive and avoid main-thread blocking:
- ViewModels are `@MainActor` to guarantee safe UI state updates.
- Heavy I/O and MIDI file processing run off-main (`Task.detached`, dedicated queues).
- `ProjectLocalWorkspaceService` is an `actor` to serialize local mutable operations safely.
- `async let` is used for parallel fetches when refreshing project detail state.
- CoreMIDI monitoring uses `AsyncStream` for controller/device/event streams.
- Security-scoped resource access is explicitly started/stopped around filesystem operations.

## Data And Backend

### Firebase Services
- Firebase Auth
- Cloud Firestore
- Firebase Storage (via upload/download services)
- Google Sign-In SDK

### Core Firestore Collections Used
- `users`
- `bands`
- `projects`
- `branches`
- `projectVersions`
- `fileVersions`
- `commits`
- `comments`
- `bandInvitations`
- `blobs` (through blob repository strategy layer)

### Firestore Indexes
Indexes are versioned in:
- `Config/Firebase/firestore.indexes.json`

Configured via:
- `firebase.json` -> `"firestore.indexes": "Config/Firebase/firestore.indexes.json"`

## Build And Run

### Prerequisites
- Xcode 17+
- Firebase project configured (default: `stemhub-b2c24`)
- GoogleService plist files present:
- `StemHub(iOS)/Resources/GoogleService-Info-iOS.plist`
- `StemHub(macOS)/Resources/GoogleService-Info-macOS.plist`

### Target Schemes
- macOS: `StemHub_macOS`
- iOS: `StemHub(iOS)`

### Local Build Commands
```bash
xcodebuild -project StemHub.xcodeproj -scheme 'StemHub_macOS' -destination 'platform=macOS' build
xcodebuild -project StemHub.xcodeproj -scheme 'StemHub(iOS)' -destination 'generic/platform=iOS' build
```

### Firebase Index Deployment
```bash
firebase deploy --only firestore:indexes
```

## Configuration Notes

- iOS Info.plist: `Config/iOS/StemHub_iOS-Info.plist`
- macOS Info.plist: `Config/macOS/StemHub_macOS-Info.plist`
- macOS entitlements (includes keychain access groups): `Config/macOS/StemHub_macOS.entitlements`
- Runtime Firebase + Google Sign-In validation is enforced by shared bootstrap/validators.

## Current Scope Notes

- macOS currently contains the full collaborative production workflow.
- iOS currently emphasizes authenticated visibility and lightweight collaboration actions (workspace snapshot, inbox actions, profile, settings).
- Export format preferences are implemented in settings; full mixdown/export pipeline is not yet implemented in this repository.
