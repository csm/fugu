# UI Decision: screen migration

📌 CREATIVE PHASE START: AppKit screen order
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Style guide loaded from `/workspace/memory-bank/style-guide.md`. This is a macOS AppKit app. macOS HIG applies. UIKit patterns do not.

## 1. Problem

The interface is four XIBs and AppKit subclasses, not view controllers or SwiftUI. `SFTPController` is the app delegate and the main window owner. A visual rewrite would break parity. The question is which toolkit and which order to use when the classes move to Swift.

Requirements:

- Same windows, menus, toolbar identifiers, and Services item `secureCopyFile`.
- Custom class module becomes `Fugu` only when that class is Swift.
- Main window moves last, because everything else is smaller and the delegate lives there.

## 2. Options

- Option A: AppKit types in Swift, one screen per branch, no visual redesign.
- Option B: Rewrite the windows in SwiftUI.
- Option C: SwiftUI only for preferences, AppKit for the browser.

## 3. Analysis

| Criterion | A AppKit port | B SwiftUI | C hybrid prefs |
| --- | --- | --- | --- |
| Looks the same | Yes | No | Prefs change |
| XIB reuse | Yes | No | Prefs discarded |
| Outlet risk | Known | Full rewrite | Split |
| HIG work | Later, separate | Mixed into the port | Mixed into prefs |

Dynamic Type, safe areas, and dark mode are real follow-ups. They are not free side effects of a language change. Doing them inside the port makes a regression impossible to attribute.

## 4. Decision

Selected: Option A.

Order, each its own Mac branch:

1. `migrate/step-05a-browser-views` — table, split, scroll, cell, image preview.
2. `migrate/step-05b-preferences` — `SFTPPrefs`, `Prefs.xib`.
3. `migrate/step-05c-scp` — `SCP.xib`.
4. `migrate/step-05d-tunnel` — `SSHTunnel.xib`.
5. `migrate/step-05e-main-window` — `SFTPController`, `SFTPMainWindow`, `MainMenu.xib`.

## 5. Implementation notes

- Swift classes that the XIB instantiates are `@objc(ClassName)` with the same Objective-C name, superclass, and action selectors.
- Set the XIB custom class module to `Fugu` in the same commit as that class's move. Do not set it in Step 1 while the class is still Objective-C.
- Keep springs and struts until a dedicated layout branch. Do not convert a XIB to Auto Layout while translating it.
- Toolbar identifiers stay the existing string constants until Step 3's enum is the single definition, and even then the stored string values stay the same.
- Smoke each branch: open that window, exercise its primary button, close it, and confirm the other windows still open.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 CREATIVE PHASE END
