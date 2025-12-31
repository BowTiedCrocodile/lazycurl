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
    if (win.height == 0) return;
    const focused = app.ui.left_panel != null and app.ui.left_panel.? == .templates;
    var header_style = if (focused) theme.accent else theme.title;
    if (focused) header_style.reverse = true;
    const title = std.fmt.allocPrint(allocator, "Templates ({d})", .{app.templates.items.len}) catch return;
    drawLine(win, 0, title, header_style);

    if (!app.ui.templates_expanded) return;

    const available = if (win.height > 1) win.height - 1 else 0;
    ensureScroll(&app.ui.templates_scroll, app.ui.selected_template, app.templates.items.len, available);
    _ = renderTemplateList(allocator, win, 1, app, theme, available);
}

fn ensureScroll(scroll: *usize, selection: ?usize, total: usize, view: usize) void {
    if (total == 0 or view == 0) {
        scroll.* = 0;
        return;
    }
    const idx = selection orelse return;
    if (idx < scroll.*) scroll.* = idx;
    if (idx >= scroll.* + view) scroll.* = idx - view + 1;
    const max_scroll = if (total > view) total - view else 0;
    if (scroll.* > max_scroll) scroll.* = max_scroll;
}


fn drawLine(win: vaxis.Window, row: u16, text: []const u8, style: vaxis.Style) void {
    if (row >= win.height) return;
    const segments = [_]vaxis.Segment{.{ .text = text, .style = style }};
    _ = win.print(&segments, .{ .row_offset = row, .wrap = .none });
}

fn renderTemplateList(
    allocator: std.mem.Allocator,
    win: vaxis.Window,
    start_row: u16,
    app: *app_mod.App,
    theme: theme_mod.Theme,
    max_rows: usize,
) u16 {
    if (start_row >= win.height) return start_row;
    if (app.templates.items.len == 0) {
        drawLine(win, start_row, "  (none)", theme.muted);
        return start_row + 1;
    }

    var row = start_row;
    const focus = app.ui.left_panel != null and app.ui.left_panel.? == .templates;
    var idx: usize = app.ui.templates_scroll;
    var rendered: usize = 0;
    while (idx < app.templates.items.len and row < win.height and rendered < max_rows) : (idx += 1) {
        const template = app.templates.items[idx];
        const selected = app.ui.selected_template != null and app.ui.selected_template.? == idx;
        var style = if (selected and focus) theme.accent else theme.text;
        if (selected and focus) style.reverse = true;
        const prefix = if (selected) ">" else " ";
        const line = std.fmt.allocPrint(allocator, " {s} {s}", .{ prefix, template.name }) catch return row;
        drawLine(win, row, line, style);
        row += 1;
        rendered += 1;
    }
    return row;
}
