const std = @import("std");
const vaxis = @import("vaxis");
const app_mod = @import("lazycurl_app");
const ui = @import("lazycurl_ui");
const execution = @import("lazycurl_execution");

pub const Size = struct {
    width: u16 = 120,
    height: u16 = 40,
};

pub const HarnessError = error{
    ExpectedScreenText,
    UnexpectedScreenText,
    NotEditing,
};

pub const Harness = struct {
    allocator: std.mem.Allocator,
    app: app_mod.App,
    runtime: app_mod.Runtime,
    screen: vaxis.Screen,
    frame_arena: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator, size: Size) !Harness {
        return .{
            .allocator = allocator,
            .app = try app_mod.App.init(allocator),
            .runtime = try app_mod.Runtime.init(allocator),
            .screen = try vaxis.Screen.init(allocator, .{
                .rows = size.height,
                .cols = size.width,
                .x_pixel = 0,
                .y_pixel = 0,
            }),
            .frame_arena = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(self: *Harness) void {
        self.frame_arena.deinit();
        self.screen.deinit(self.allocator);
        self.runtime.deinit();
        self.app.deinit();
    }

    pub fn render(self: *Harness) !void {
        self.screen.clear();
        self.frame_arena.deinit();
        self.frame_arena = std.heap.ArenaAllocator.init(self.allocator);
        const frame_alloc = self.frame_arena.allocator();
        try ui.render(frame_alloc, self.window(), &self.app, &self.runtime);
    }

    pub fn press(self: *Harness, code: app_mod.KeyCode) !void {
        _ = try self.app.handleKey(.{ .code = code }, &self.runtime);
    }

    pub fn ctrl(self: *Harness, ch: u8) !void {
        _ = try self.app.handleKey(.{ .code = .{ .char = ch }, .mods = .{ .ctrl = true } }, &self.runtime);
    }

    pub fn typeText(self: *Harness, text: []const u8) !void {
        for (text) |byte| {
            try self.press(.{ .char = byte });
        }
    }

    pub fn paste(self: *Harness, text: []const u8) !void {
        try self.press(.{ .paste = text });
    }

    pub fn replaceEditingText(self: *Harness, text: []const u8) !void {
        if (self.app.state != .editing or self.app.editing_field == null) return HarnessError.NotEditing;
        if (self.app.editing_field.? == .body) {
            try self.app.ui.body_input.reset(text);
        } else {
            try self.app.ui.edit_input.reset(text);
        }
    }

    pub fn commitEdit(self: *Harness) !void {
        if (self.app.state != .editing or self.app.editing_field == null) return HarnessError.NotEditing;
        if (self.app.editing_field.? == .body) {
            try self.press(.f2);
        } else {
            try self.press(.enter);
        }
    }

    pub fn setOutput(self: *Harness, stdout: []const u8) !void {
        const result = execution.executor.ExecutionResult{
            .command = try self.allocator.dupe(u8, "curl https://example.test"),
            .exit_code = 0,
            .stdout = try self.allocator.dupe(u8, stdout),
            .stderr = try self.allocator.dupe(u8, ""),
            .duration_ns = 12 * std.time.ns_per_ms,
            .error_message = null,
        };
        self.runtime.setResult(result);
    }

    pub fn rowText(self: *Harness, allocator: std.mem.Allocator, row: u16) ![]u8 {
        var line = try std.ArrayList(u8).initCapacity(allocator, self.screen.width);
        defer line.deinit(allocator);
        var col: u16 = 0;
        while (col < self.screen.width) : (col += 1) {
            const cell = self.screen.readCell(col, row) orelse continue;
            try line.appendSlice(allocator, cell.char.grapheme);
        }
        return try trimRightOwned(allocator, line.items);
    }

    pub fn screenText(self: *Harness, allocator: std.mem.Allocator) ![]u8 {
        var out = try std.ArrayList(u8).initCapacity(allocator, self.screen.width * self.screen.height);
        defer out.deinit(allocator);
        var row: u16 = 0;
        while (row < self.screen.height) : (row += 1) {
            if (row > 0) try out.append(allocator, '\n');
            const line = try self.rowText(allocator, row);
            defer allocator.free(line);
            try out.appendSlice(allocator, line);
        }
        return out.toOwnedSlice(allocator);
    }

    pub fn expectContains(self: *Harness, needle: []const u8) !void {
        const text = try self.screenText(self.allocator);
        defer self.allocator.free(text);
        if (std.mem.indexOf(u8, text, needle) == null) {
            std.debug.print("missing screen text: {s}\n--- screen ---\n{s}\n", .{ needle, text });
            return HarnessError.ExpectedScreenText;
        }
    }

    pub fn expectNotContains(self: *Harness, needle: []const u8) !void {
        const text = try self.screenText(self.allocator);
        defer self.allocator.free(text);
        if (std.mem.indexOf(u8, text, needle) != null) {
            std.debug.print("unexpected screen text: {s}\n--- screen ---\n{s}\n", .{ needle, text });
            return HarnessError.UnexpectedScreenText;
        }
    }

    fn window(self: *Harness) vaxis.Window {
        return .{
            .x_off = 0,
            .y_off = 0,
            .parent_x_off = 0,
            .parent_y_off = 0,
            .width = self.screen.width,
            .height = self.screen.height,
            .screen = &self.screen,
        };
    }
};

fn trimRightOwned(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const trimmed = std.mem.trimRight(u8, input, " ");
    return allocator.dupe(u8, trimmed);
}
