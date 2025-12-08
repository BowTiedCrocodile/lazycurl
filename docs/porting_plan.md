# Porting Plan

- Step 1 – Source Audit & Feature Freeze
  Inventory every Rust module (app, command, execution, models, persistence, ui) plus assets like SHORTCUTS.md and tvrl_design_document.md.
  Capture the user-visible feature list (tabs, templates, env vars, command execution) plus shortcuts so they become migration acceptance
  tests. Outcome: markdown checklist describing required behavior in Zig and any Rust-only dependencies to replace.
- Step 2 – Zig Workspace Foundations
  Flesh out build.zig/build.zig.zon to pull libvaxis as a dependency, define separate app and core modules (src/zvrl/core/*.zig), and add
  zig build run/test/fmt shortcuts to dev.sh. Verify zig build run still succeeds with placeholder code and document required Zig version +
  libvaxis fetch instructions.
- Step 3 – Data Model Port
  Translate models::command, environment, and template into Zig structs/enums with helper methods (e.g., HttpMethod, CurlCommand,
  RequestBody). Replace uuid usage with std.uuid or deterministic counters, and port chrono timestamps to std.time. Add serialization
  scaffolding (likely std.json). Create unit tests ensuring Zig models default the same way as Rust ones.
- Step 4 – Command Builder Logic
  Re‑implement CommandBuilder::build, option quoting, env substitution, and query param handling in Zig (src/zvrl/command/builder.zig).
  Provide helpers for regex-like substitutions via std.mem.tokenize/std.regex. Port the test cases from builder.rs verbatim to Zig’s test
  blocks to guarantee curl strings stay identical.
- Step 5 – Persistence & Sample Data
  Stub out JSON (or TOML) persistence APIs mirroring persistence in Rust so templates/environments can be saved under ~/.config/tvrl/.
  Implement load/save functions returning Zig errors so later UI work can surface failures. Seed demo templates/environments in Zig the same
  way App::new does to keep UX parity until real persistence is wired.
- Step 6 – Command Execution Backend
  Create execution/executor.zig that wraps std.ChildProcess to spawn the system curl, stream stdout/stderr incrementally, and produce a Zig
  ExecutionResult. Mirror Rust’s exit-code mapping so UI can show friendly errors. Add async-ish polling using libvaxis’ event loop or a
  custom thread to avoid blocking the TUI.
- Step 7 – Event System & App State Machine
  Port App, AppState, UiState, selection enums, and cursor blink timers into Zig (src/zvrl/app.zig). Recreate the key-handling table, tab
  navigation, dropdown logic, template loading, and editing modes as pure state transitions independent of any UI library. Add thorough
  tests for functions like navigate_field_up and execute_command using Zig’s testing harness.
- Step 8 – Libvaxis Terminal Harness
  Implement the Zig equivalent of main.rs: initialize libvaxis, set raw mode, own the alternate screen, and drive a render/event loop with
  tick timers (using std.time.Timer and libvaxis input). Ensure graceful shutdown mirrors the Rust cleanup path. Provide plumbing that calls
  the App state machine and publishes redraw requests.
- Step 9 – UI Component Migration
  Recreate each Ratatui component (StatusBar, TemplatesTree, CommandBuilder, UrlContainer, CommandDisplay, OptionsPanel, OutputPanel)
  as libvaxis widgets/modules. Start with layout scaffolding (vertical chunks, horizontal splits), then port drawing logic, colors, and
  highlight rules. Validate proportions (status bar height, panel widths) against the design doc.
- Step 10 – Text Editing & Input Widgets
  Replace tui_textarea behavior with a Zig-native text area abstraction: handle cursor movement, insert/delete, scrolling, and syntax-
  highlighting placeholders. Integrate it into the Body tab and ensure keystrokes map to App editing state just like the original.
- Step 11 – Template/Environment/History Panels
  Implement scrollable lists, expand/collapse states, and selection indicators in Zig. Hook them to persistence once Step 5 is complete so
  saving/loading actually mutates disk artifacts. Add commands for toggling panels and editing entries, aligning keyboard shortcuts with
  SHORTCUTS.md.
- Step 12 – Testing, Parity Diffs, and Cleanup
  Run zig build test regularly, and add snapshot-style tests for command rendering and option ordering. Execute the Zig binary to verify
  each feature in the acceptance checklist from Step 1. Once parity is confirmed, retire the Rust build (Cargo files) or leave them behind a
  feature flag, update README.md to describe the Zig build, and ensure AGENTS.md references the new tooling.