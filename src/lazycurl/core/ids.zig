const std = @import("std");

pub const Timestamp = i64;

pub fn nowTimestamp() Timestamp {
    return std.Io.Clock.real.now(std.Options.debug_io).toSeconds();
}

pub fn nowMilliseconds() i64 {
    return std.Io.Clock.awake.now(std.Options.debug_io).toMilliseconds();
}

pub const IdGenerator = struct {
    next: u64 = 1,

    pub fn nextId(self: *IdGenerator) u64 {
        const id = self.next;
        self.next += 1;
        return id;
    }
};
