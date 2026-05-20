const std = @import("std");
const harness_mod = @import("lazycurl_harness");

const Harness = harness_mod.Harness;

test "agent can inspect the initial TUI frame" {
    var h = try Harness.init(std.testing.allocator, .{});
    defer h.deinit();

    try h.render();

    try h.expectContains("State: normal | Tab: url");
    try h.expectContains("curl https://");
    try h.expectContains("[URL]");
    try h.expectContains("[ ] New query param");
}

test "agent can edit url and method through UI actions" {
    var h = try Harness.init(std.testing.allocator, .{});
    defer h.deinit();

    try h.press(.enter);
    try h.replaceEditingText("https://api.example.test/v1/users");
    try h.commitEdit();
    try h.press(.left);
    try h.press(.enter);
    try h.press(.down);
    try h.press(.enter);
    try h.render();

    try h.expectContains("State: normal | Tab: url");
    try h.expectContains(">  POST");
    try h.expectContains("curl -X POST https://api.example.test/v1/users");
}

test "agent can add header and assert command preview regression" {
    var h = try Harness.init(std.testing.allocator, .{});
    defer h.deinit();

    try h.press(.tab);
    try h.press(.enter);
    try h.typeText("Accept");
    try h.press(.enter);
    try h.typeText("application/json");
    try h.press(.enter);
    try h.render();

    try h.expectContains("State: normal | Tab: headers");
    try h.expectContains("[x] Accept: application/json");
    try h.expectContains("curl -H 'Accept: application/json' https://");
}

test "agent can validate rendered output state without running curl" {
    var h = try Harness.init(std.testing.allocator, .{});
    defer h.deinit();

    try h.setOutput("{\"ok\":true}\n__LAZYCURL_HTTP_STATUS__201\n");
    try h.render();

    try h.expectContains("HTTP 201");
    try h.expectContains("Time: 12 ms");
    try h.expectContains("{\"ok\":true}");
    try h.expectNotContains("__LAZYCURL_HTTP_STATUS__201");
}
