# UI Acceptance Harness

read_when: changing TUI behavior, adding keyboard flows, or reviewing UI regressions.

The TUI harness lives in `src/lazycurl/testing/harness.zig`.

It runs in process:

- drives the real `App.handleKey` state machine with `KeyInput` values
- renders the real `ui.render` tree into an in-memory `vaxis.Screen`
- exposes the screen as text so tests can assert visible UI state
- can inject output results without launching `curl`

Run acceptance tests:

```bash
zig build acceptance
```

`zig build test` also runs the acceptance suite.

## Writing Scenarios

Add scenarios in `test/ui_acceptance.zig`.

Use key-level actions for user flows:

```zig
var h = try Harness.init(std.testing.allocator, .{});
defer h.deinit();

try h.press(.tab);
try h.press(.enter);
try h.typeText("Accept");
try h.press(.enter);
try h.typeText("application/json");
try h.press(.enter);
try h.render();

try h.expectContains("[x] Accept: application/json");
```

Use `replaceEditingText` when a scenario needs to set a field quickly after entering edit mode. It still goes through the app's edit/commit path.

Use `setOutput` to validate output rendering without shelling out:

```zig
try h.setOutput("{\"ok\":true}\n__LAZYCURL_HTTP_STATUS__201\n");
try h.render();
try h.expectContains("HTTP 201");
```

## Mapping UI Use To Tests

Prefer this shape for acceptance tests:

1. Drive a user action sequence with `press`, `ctrl`, `typeText`, or `paste`.
2. Call `render`.
3. Assert text that a user would see, such as status, selected tab, command preview, headers, output status, or body text.
4. Add direct app-state assertions only when visible text cannot prove the regression risk.

Keep scenario assertions stable. Avoid checking box-drawing characters, colors, exact whitespace, or full-screen snapshots unless the layout itself is the behavior under test.
