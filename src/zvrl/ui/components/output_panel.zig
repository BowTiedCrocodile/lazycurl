const std = @import("std");
const vaxis = @import("vaxis");
const app_mod = @import("zvrl_app");
const theme_mod = @import("../theme.zig");

pub fn render(win: vaxis.Window, runtime: *app_mod.Runtime, theme: theme_mod.Theme) void {
    drawLine(win, 0, "Output", theme.title);

    const status_line = if (runtime.active_job != null)
        "Status: running"
    else if (runtime.last_result != null)
        "Status: complete"
    else
        "Status: idle";

    const status_style = if (runtime.active_job != null) theme.accent else if (runtime.last_result != null) theme.text else theme.muted;
    drawLine(win, 1, status_line, status_style);

    var row: u16 = 2;
    if (runtime.last_result) |result| {
        var buffer: [128]u8 = undefined;
        const exit_line = if (result.exit_code) |code|
            std.fmt.bufPrint(&buffer, "Exit: {d}", .{code}) catch return
        else
            std.fmt.bufPrint(&buffer, "Exit: unknown", .{}) catch return;
        const exit_style = if (result.exit_code != null and result.exit_code.? == 0) theme.success else theme.error_style;
        drawLine(win, row, exit_line, exit_style);
        row += 1;

        const duration_ms = result.duration_ns / std.time.ns_per_ms;
        const dur_line = std.fmt.bufPrint(&buffer, "Time: {d} ms", .{duration_ms}) catch return;
        drawLine(win, row, dur_line, theme.muted);
        row += 1;
    }

    if (row < win.height) {
        drawLine(win, row, "Stdout:", theme.muted);
        row += 1;
        row = drawOutputLines(win, row, runtimeOutput(runtime, .stdout), theme.text);
    }

    if (row < win.height) {
        drawLine(win, row, "Stderr:", theme.muted);
        row += 1;
        _ = drawOutputLines(win, row, runtimeOutput(runtime, .stderr), theme.error_style);
    }
}

const OutputKind = enum { stdout, stderr };

fn runtimeOutput(runtime: *app_mod.Runtime, kind: OutputKind) []const u8 {
    if (runtime.active_job != null) {
        return switch (kind) {
            .stdout => runtime.stream_stdout.items,
            .stderr => runtime.stream_stderr.items,
        };
    }
    if (runtime.last_result) |result| {
        return switch (kind) {
            .stdout => result.stdout,
            .stderr => result.stderr,
        };
    }
    return "";
}

fn drawOutputLines(win: vaxis.Window, start_row: u16, text: []const u8, style: vaxis.Style) u16 {
    var row = start_row;
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |line| {
        if (row >= win.height) break;
        drawLine(win, row, line, style);
        row += 1;
    }
    return row;
}

fn drawLine(win: vaxis.Window, row: u16, text: []const u8, style: vaxis.Style) void {
    if (row >= win.height) return;
    const segments = [_]vaxis.Segment{.{ .text = text, .style = style }};
    _ = win.print(&segments, .{ .row_offset = row, .wrap = .none });
}
