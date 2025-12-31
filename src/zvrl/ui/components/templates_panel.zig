const std = @import("std");
const vaxis = @import("vaxis");
const app_mod = @import("zvrl_app");
const theme_mod = @import("../theme.zig");

pub fn render(
    allocator: std.mem.Allocator,
    win: vaxis.Window,
    app: *app_mod.App,
    theme: theme_mod.Theme,
) void {
    drawLine(win, 0, "Templates", theme.title);
    const count = app.templates.items.len;
    const selected = app.ui.selected_template;

    const info = std.fmt.allocPrint(allocator, "Count: {d}", .{count}) catch return;
    drawLine(win, 1, info, theme.muted);

    if (count == 0) {
        drawLine(win, 2, "No templates", theme.muted);
        return;
    }

    var row: u16 = 2;
    for (app.templates.items, 0..) |template, idx| {
        if (row >= win.height) break;
        var style = theme.text;
        if (selected != null and selected.? == idx) {
            style = theme.accent;
            style.reverse = true;
        }
        const line = std.fmt.allocPrint(allocator, "{d}. {s}", .{ idx + 1, template.name }) catch return;
        drawLine(win, row, line, style);
        row += 1;
    }
}

fn drawLine(win: vaxis.Window, row: u16, text: []const u8, style: vaxis.Style) void {
    const segments = [_]vaxis.Segment{.{ .text = text, .style = style }};
    _ = win.print(&segments, .{ .row_offset = row, .wrap = .none });
}
