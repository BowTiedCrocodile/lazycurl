const std = @import("std");
const vaxis = @import("vaxis");
const app_mod = @import("zvrl_app");
const theme_mod = @import("../theme.zig");

pub fn render(win: vaxis.Window, app: *app_mod.App, theme: theme_mod.Theme) void {
    drawLine(win, 0, "Curl Options", theme.title);

    if (app.current_command.options.items.len == 0) {
        drawLine(win, 1, "No options", theme.muted);
        return;
    }

    var row: u16 = 1;
    for (app.current_command.options.items, 0..) |option, idx| {
        if (row >= win.height) break;
        const enabled = if (option.enabled) "[x]" else "[ ]";
        const is_selected = isOptionSelected(app, idx);
        var style = if (is_selected) theme.accent else theme.text;
        if (is_selected) style.reverse = true;

        var buffer: [160]u8 = undefined;
        const line = if (option.value) |value|
            std.fmt.bufPrint(&buffer, "{s} {s} {s}", .{ enabled, option.flag, value }) catch return
        else
            std.fmt.bufPrint(&buffer, "{s} {s}", .{ enabled, option.flag }) catch return;

        drawLine(win, row, line, style);
        row += 1;
    }
}

fn drawLine(win: vaxis.Window, row: u16, text: []const u8, style: vaxis.Style) void {
    if (row >= win.height) return;
    const segments = [_]vaxis.Segment{.{ .text = text, .style = style }};
    _ = win.print(&segments, .{ .row_offset = row, .wrap = .none });
}

fn isOptionSelected(app: *app_mod.App, idx: usize) bool {
    if (app.ui.selected_template != null) return false;
    return switch (app.ui.selected_field) {
        .options => |sel| sel == idx,
        else => false,
    };
}
