const vaxis = @import("vaxis");
const app_mod = @import("zvrl_app");
const theme_mod = @import("../theme.zig");

pub fn render(win: vaxis.Window, app: *app_mod.App, theme: theme_mod.Theme) void {
    drawLine(win, 0, "Shortcuts", theme.title);
    drawLine(win, 1, "Ctrl+X Quit", theme.text);
    drawLine(win, 2, "Ctrl+R/F5 Run", theme.text);
    drawLine(win, 3, "Enter Edit", theme.text);
    drawLine(win, 4, "Tab Cycle", theme.text);

    const section_row: u16 = 6;
    if (section_row >= win.height) return;
    drawLine(win, section_row, "Context", theme.title);
    renderContext(win, app, theme, section_row + 1);
}

fn drawLine(win: vaxis.Window, row: u16, text: []const u8, style: vaxis.Style) void {
    const segments = [_]vaxis.Segment{.{ .text = text, .style = style }};
    _ = win.print(&segments, .{ .row_offset = row, .wrap = .none });
}

fn renderContext(win: vaxis.Window, app: *app_mod.App, theme: theme_mod.Theme, start_row: u16) void {
    if (start_row >= win.height) return;
    const lines = contextLines(app);
    var row = start_row;
    for (lines) |line| {
        if (row >= win.height) break;
        drawLine(win, row, line, theme.muted);
        row += 1;
    }
}

fn contextLines(app: *app_mod.App) []const []const u8 {
    if (app.state == .editing) {
        return &[_][]const u8{
            "Enter Save",
            "Esc Cancel",
        };
    }
    if (app.state == .method_dropdown) {
        return &[_][]const u8{
            "Up/Down Select",
            "Enter Apply",
            "Esc Cancel",
        };
    }
    if (app.ui.left_panel) |panel| {
        return switch (panel) {
            .templates => &[_][]const u8{
                "Enter Load",
                "F2 Rename",
            },
            .environments => &[_][]const u8{
                "Enter Select",
            },
            .history => &[_][]const u8{
                "Enter Load",
            },
        };
    }
    return &[_][]const u8{
        "Arrows Navigate",
        "Tab Switch",
    };
}
