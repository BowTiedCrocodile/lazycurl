const std = @import("std");
const vaxis = @import("vaxis");
const app_mod = @import("lazycurl_app");
const theme_mod = @import("../theme.zig");

pub fn render(allocator: std.mem.Allocator, win: vaxis.Window, app: *app_mod.App, theme: theme_mod.Theme) void {
    if (win.height == 0) return;
    const line = buildShortcutLine(allocator, app) catch return;
    drawLine(win, 0, line, theme.muted);
}

fn drawLine(win: vaxis.Window, row: u16, text: []const u8, style: vaxis.Style) void {
    const segments = [_]vaxis.Segment{.{ .text = text, .style = style }};
    _ = win.print(&segments, .{ .row_offset = row, .wrap = .none });
}

fn contextLines(app: *app_mod.App) []const []const u8 {
    if (app.state == .editing) {
        if (app.editing_field == .body) {
            return &[_][]const u8{
                "Ctrl+S/F2 Save",
                "Enter Newline",
                "Esc Cancel",
            };
        }
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
                "Enter Load/Toggle",
                "F2 Rename",
                "F3 Save Template",
                "F4 New Folder",
                "F6 Delete Folder",
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
        "Tab/Shift+Tab Switch",
    };
}

fn baseLines() []const []const u8 {
    return &[_][]const u8{
        "Ctrl+R/F5 Run",
        "Ctrl+X/F10 Quit",
        "PgUp/PgDn Scroll Output",
    };
}

fn buildShortcutLine(allocator: std.mem.Allocator, app: *app_mod.App) ![]const u8 {
    const base = baseLines();
    const context = contextLines(app);
    const total = base.len + context.len;
    if (total == 0) return "";

    var joined = try std.ArrayList(u8).initCapacity(allocator, 0);
    try joined.ensureTotalCapacity(allocator, 64);
    var idx: usize = 0;
    for (base) |entry| {
        if (idx > 0) try joined.appendSlice(allocator, " | ");
        try joined.appendSlice(allocator, entry);
        idx += 1;
    }
    for (context) |entry| {
        if (idx > 0) try joined.appendSlice(allocator, " | ");
        try joined.appendSlice(allocator, entry);
        idx += 1;
    }
    return joined.toOwnedSlice(allocator);
}
