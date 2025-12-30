const std = @import("std");
const core = @import("zvrl_core");

const Allocator = std.mem.Allocator;
const CurlCommand = core.models.command.CurlCommand;
const RequestBody = core.models.command.RequestBody;
const Environment = core.models.environment.Environment;
const CommandTemplate = core.models.template.CommandTemplate;

pub const StoragePaths = struct {
    base_dir: []u8,
    templates_dir: []u8,
    environments_dir: []u8,
    history_file: []u8,
    templates_file: []u8,
    environments_file: []u8,

    pub fn deinit(self: *StoragePaths, allocator: Allocator) void {
        allocator.free(self.base_dir);
        allocator.free(self.templates_dir);
        allocator.free(self.environments_dir);
        allocator.free(self.history_file);
        allocator.free(self.templates_file);
        allocator.free(self.environments_file);
    }
};

pub const PersistenceError = error{
    NotImplemented,
};

pub fn resolvePaths(allocator: Allocator) !StoragePaths {
    const base_dir = try std.fs.getAppDataDir(allocator, "tvrl");
    const templates_dir = try std.fs.path.join(allocator, &.{ base_dir, "templates" });
    const environments_dir = try std.fs.path.join(allocator, &.{ base_dir, "environments" });
    const history_file = try std.fs.path.join(allocator, &.{ base_dir, "history.json" });
    const templates_file = try std.fs.path.join(allocator, &.{ base_dir, "templates.json" });
    const environments_file = try std.fs.path.join(allocator, &.{ base_dir, "environments.json" });

    return .{
        .base_dir = base_dir,
        .templates_dir = templates_dir,
        .environments_dir = environments_dir,
        .history_file = history_file,
        .templates_file = templates_file,
        .environments_file = environments_file,
    };
}

pub fn ensureStorageDirs(paths: *const StoragePaths) !void {
    const cwd = std.fs.cwd();
    try cwd.makePath(paths.base_dir);
    try cwd.makePath(paths.templates_dir);
    try cwd.makePath(paths.environments_dir);
}

pub fn loadTemplates(allocator: Allocator, generator: *core.IdGenerator) !std.ArrayList(CommandTemplate) {
    var paths = try resolvePaths(allocator);
    defer paths.deinit(allocator);

    const cwd = std.fs.cwd();
    if (cwd.openFile(paths.templates_file, .{ .mode = .read_only })) |file| {
        file.close();
        return PersistenceError.NotImplemented;
    } else |err| switch (err) {
        error.FileNotFound => return seedTemplates(allocator, generator),
        else => return err,
    }
}

pub fn loadEnvironments(allocator: Allocator, generator: *core.IdGenerator) !std.ArrayList(Environment) {
    var paths = try resolvePaths(allocator);
    defer paths.deinit(allocator);

    const cwd = std.fs.cwd();
    if (cwd.openFile(paths.environments_file, .{ .mode = .read_only })) |file| {
        file.close();
        return PersistenceError.NotImplemented;
    } else |err| switch (err) {
        error.FileNotFound => return seedEnvironments(allocator, generator),
        else => return err,
    }
}

pub fn loadHistory(allocator: Allocator) !std.ArrayList(CurlCommand) {
    var paths = try resolvePaths(allocator);
    defer paths.deinit(allocator);

    const cwd = std.fs.cwd();
    if (cwd.openFile(paths.history_file, .{ .mode = .read_only })) |file| {
        file.close();
        return PersistenceError.NotImplemented;
    } else |err| switch (err) {
        error.FileNotFound => return std.ArrayList(CurlCommand).initCapacity(allocator, 0),
        else => return err,
    }
}

pub fn saveTemplates(allocator: Allocator, templates: []const CommandTemplate) !void {
    _ = templates;
    var paths = try resolvePaths(allocator);
    defer paths.deinit(allocator);
    try ensureStorageDirs(&paths);
    return PersistenceError.NotImplemented;
}

pub fn saveEnvironments(allocator: Allocator, environments: []const Environment) !void {
    _ = environments;
    var paths = try resolvePaths(allocator);
    defer paths.deinit(allocator);
    try ensureStorageDirs(&paths);
    return PersistenceError.NotImplemented;
}

pub fn saveHistory(allocator: Allocator, history: []const CurlCommand) !void {
    _ = history;
    var paths = try resolvePaths(allocator);
    defer paths.deinit(allocator);
    try ensureStorageDirs(&paths);
    return PersistenceError.NotImplemented;
}

pub fn seedTemplates(allocator: Allocator, generator: *core.IdGenerator) !std.ArrayList(CommandTemplate) {
    var templates = try std.ArrayList(CommandTemplate).initCapacity(allocator, 2);

    var get_command = try CurlCommand.init(allocator, generator);
    allocator.free(get_command.name);
    get_command.name = try allocator.dupe(u8, "GET Example");
    allocator.free(get_command.url);
    get_command.url = try allocator.dupe(u8, "https://httpbin.org/get");
    get_command.method = .get;
    try get_command.addOption(generator, "-i", null);

    var get_template = try CommandTemplate.init(allocator, generator, "GET Example", get_command);
    try get_template.setDescription("Simple GET request");
    try get_template.setCategory("Examples");
    try templates.append(allocator, get_template);

    var post_command = try CurlCommand.init(allocator, generator);
    allocator.free(post_command.name);
    post_command.name = try allocator.dupe(u8, "POST JSON");
    allocator.free(post_command.url);
    post_command.url = try allocator.dupe(u8, "https://httpbin.org/post");
    post_command.method = .post;
    try post_command.addHeader(generator, "Content-Type", "application/json");
    const body = try allocator.dupe(u8, "{\"key\": \"value\"}");
    post_command.setBody(.{ .raw = body });
    try post_command.addOption(generator, "-i", null);

    var post_template = try CommandTemplate.init(allocator, generator, "POST JSON", post_command);
    try post_template.setDescription("POST with JSON body");
    try post_template.setCategory("Examples");
    try templates.append(allocator, post_template);

    return templates;
}

pub fn seedEnvironments(allocator: Allocator, generator: *core.IdGenerator) !std.ArrayList(Environment) {
    var environments = try std.ArrayList(Environment).initCapacity(allocator, 1);
    const env = try Environment.init(allocator, generator, "Default");
    try environments.append(allocator, env);
    return environments;
}

pub fn deinitTemplates(allocator: Allocator, templates: *std.ArrayList(CommandTemplate)) void {
    for (templates.items) |*template| {
        template.deinit();
    }
    templates.deinit(allocator);
}

pub fn deinitEnvironments(allocator: Allocator, environments: *std.ArrayList(Environment)) void {
    for (environments.items) |*env| {
        env.deinit();
    }
    environments.deinit(allocator);
}

pub fn deinitHistory(allocator: Allocator, history: *std.ArrayList(CurlCommand)) void {
    for (history.items) |*command| {
        command.deinit();
    }
    history.deinit(allocator);
}

test "seed data mirrors rust defaults" {
    var generator = core.IdGenerator{};
    var templates = try seedTemplates(std.testing.allocator, &generator);
    defer deinitTemplates(std.testing.allocator, &templates);

    var environments = try seedEnvironments(std.testing.allocator, &generator);
    defer deinitEnvironments(std.testing.allocator, &environments);

    try std.testing.expectEqual(@as(usize, 2), templates.items.len);
    try std.testing.expectEqual(@as(usize, 1), environments.items.len);
}
