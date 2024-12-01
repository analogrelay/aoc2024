const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Missing input file", .{});
        return;
    }
    var buffer: [1024]u8 = undefined;
    const path = std.mem.span(std.os.argv[1]);
    var lines = try utils.fileByLines(path, &buffer);
    while (try lines.next()) |line| {
        std.log.info("Line: {s}", .{line});
    }
}
