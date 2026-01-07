const vaxis = @import("vaxis");
const theme_mod = @import("../theme.zig");

pub fn render(win: vaxis.Window, theme: theme_mod.Theme) void {
    drawLine(win, 0, "Shortcuts", theme.title);
    drawLine(win, 1, "Ctrl+X Quit", theme.text);
    drawLine(win, 2, "Ctrl+R/F5 Run", theme.text);
    drawLine(win, 3, "Enter Edit", theme.text);
    drawLine(win, 4, "Tab Cycle", theme.text);
}

fn drawLine(win: vaxis.Window, row: u16, text: []const u8, style: vaxis.Style) void {
    const segments = [_]vaxis.Segment{.{ .text = text, .style = style }};
    _ = win.print(&segments, .{ .row_offset = row, .wrap = .none });
}
