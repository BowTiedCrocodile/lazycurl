# Step 1 – Source Audit & Feature Checklist

## Modules and Responsibilities
- `src/main.rs`: Crossterm bootstrapper that toggles raw mode/alternate screen, owns the `Terminal`, and drives the render/event loop.
- `src/app.rs`: Master application state machine – tabs, selection logic, cursor blinking, templates/env/history toggles, and command execution triggers.
- `src/command/*`: Curl command builder (`builder.rs`), option metadata (`options.rs`), and validation helpers; centralizes env-var substitution.
- `src/execution/*`: Async executor wrapping `curl` via `tokio` and `std::process`, provides streaming output + enriched error messages.
- `src/models/*`: Data definitions for `CurlCommand`, `RequestBody`, headers, query params, templates, and environments (with chrono timestamps + UUIDs).
- `src/persistence/*`: Serialization, encryption helpers, and filesystem paths (leverages `serde`, `dirs`, `aes-gcm`, `base64`).
- `src/ui/*`: Ratatui theme, event pump, and every composable widget (`components/`).
- Docs: `SHORTCUTS.md`, `docs/tvrl_design_document.md`, `README.md`, `AGENTS.md`, and `dev.sh` (development workflow helper).

## User-Visible Feature Inventory
- **Layout**: Status bar (app state, messages), left templates tree, method dropdown, URL editor with tabs (URL/Headers/Body/Curl Options), command preview, and output pane.
- **Navigation**: Tab cycling via Tab/Shift+Tab or Ctrl+Right/Left; arrow key navigation inside lists; Ctrl+Q exit; F1 help view; Esc cancels edit dialogs.
- **Templates & History**: Expand/collapse panels, select template to load, maintain execution history list, toggle with Ctrl+T/E/H.
- **Command Builder**: Method picker, URL + query params, headers table with enable/disable, body textarea supporting raw/form/binary, categorized curl option palette (command-line options vs active ones).
- **Environment Handling**: Named environments with variable substitution syntax `{{key[:default]}}`, secrets flag, editing mode.
- **Command Execution**: Build command string in real time, copy to clipboard (Ctrl+C), execute via F5/Ctrl+R, stream stdout/stderr, show exit code/time/errors, store history entry.
- **Keyboard Shortcuts**: Now documented in `README.md` (shortcuts section) – navigation, toggles, creation (`Ctrl+N`), save template (`Ctrl+S`), etc.
- **Persistence Expectations**: Templates, environments, and history survive restarts; secrets encrypted; default templates/environments seeded on first run.

## Rust Dependencies Requiring Zig Replacements
| Rust Crate | Purpose | Zig Replacement Strategy |
| --- | --- | --- |
| ratatui | Layout/rendering widgets | libvaxis layouts + custom widgets |
| crossterm | Terminal mode + events | libvaxis terminal/input stack |
| tui-textarea | Text editing widget | Custom Zig textarea atop libvaxis |
| tokio | Async runtime for executor | Zig async/threads (`std.Thread`, event loop) |
| serde / serde_json / toml | Serialization | `std.json`, manual TOML parsing (or JSON-only) |
| regex | Env substitution patterns | `std.regex` or custom parser |
| chrono | Time stamps | `std.time` |
| uuid | IDs | `std.uuid` or counter-based IDs |
| dirs | Config/data paths | `std.fs.getAppDataDir` / platform-specific helpers |
| aes-gcm / base64 | Secret encryption | `std.crypto.aead.aes_gcm` + `std.base64` |
| which | Locate curl | `std.fs.cwd().openIterableDir("/usr/bin")` equivalent search or rely on PATH execution |
| urlencoding / url | Query encoding | `std.Uri` or manual percent-encoding |

## Migration Acceptance Checklist
- [ ] Zig binary exposes identical panes/layout proportions as described above.
- [ ] All keyboard shortcuts in `README.md` (shortcuts section) behave the same, including template/history toggles and help modal.
- [ ] Command preview updates in real time with identical quoting/ordering logic to Rust `CommandBuilder`.
- [ ] Environment variable substitution accepts `{{var}}` and `{{var:default}}` forms everywhere (URL, headers, body, options).
- [ ] Curl execution pipeline spawns system `curl`, streams stdout/stderr, and surfaces exit code + friendly error text.
- [ ] Templates, environments, and history persist between sessions with initial seed data matching Rust defaults.
- [ ] Secrets remain masked in UI and encrypted on disk.
- [ ] Body editor supports raw text, form-data, and binary modes with navigation consistent with the Rust textarea.
- [ ] UI components (status bar, tabs, option categories, output panel) render with theming equivalent to `Theme::new`.
- [ ] Tests exist for Zig models, command builder, and key App state transitions mirroring Rust coverage.
