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

    var reports = std.ArrayList([]?isize).init(std.heap.c_allocator);
    defer reports.deinit();

    var levels = std.ArrayList(?isize).init(std.heap.c_allocator);

    while (try lines.next()) |line| {
        var splat = std.mem.splitSequence(u8, line, " ");

        while (splat.next()) |val| {
            try levels.append(try std.fmt.parseInt(isize, val, 10));
        }

        try reports.append(try levels.toOwnedSlice());
    }

    const reports_slice = try reports.toOwnedSlice();
    const part1 = getSafeCount(reports_slice, false);
    std.debug.print("Safe count, part 1: {}\n", .{part1});
    const part2 = getSafeCount(reports_slice, true);
    std.debug.print("Safe count, part 2: {}\n", .{part2});
}

fn getSafeCount(reports: [][]?isize, use_problem_damper: bool) usize {
    var safe_count: usize = 0;
    for (reports) |report| {
        if (reportIsSafeWithoutDamper(report) or (use_problem_damper and reportIsSafeWithDamper(report) != null)) {
            safe_count += 1;
        }
    }

    return safe_count;
}

fn reportIsSafeWithoutDamper(levels: []const ?isize) bool {
    return reportIsSafe(levels);
}

fn reportIsSafeWithDamper(levels: []?isize) ?usize {
    for (0..levels.len) |mask| {
        const removed = levels[mask];
        levels[mask] = null;
        if (reportIsSafe(levels)) {
            return mask;
        }
        levels[mask] = removed;
    }

    return null;
}

fn reportIsSafe(levels: []const ?isize) bool {
    var direction: ?isize = null;
    for (1..levels.len) |i| {
        if (levels[i] == null) {
            // This element is a hole, continue.
            continue;
        }
        var previous = levels[i - 1];
        if (previous == null) {
            if (i == 1) {
                // Can't look back, just continue. We're the start now, so i==2 will check our value.
                continue;
            }
            previous = levels[i - 2];
        }
        const delta = levels[i].? - previous.?;
        if (direction == null) {
            direction = delta;
        }
        if (!levelIsSafe(direction.?, delta)) {
            return false;
        }
    }

    // None of the levels were unsafe, so we're safe!
    return true;
}

fn levelIsSafe(direction: isize, delta: isize) bool {
    if (std.math.sign(direction) != std.math.sign(delta)) {
        // Unsafe! The direction of this delta is different from the first one.
        return false;
    }

    const magnitude = @abs(delta);
    if (magnitude < 1 or magnitude > 3) {
        // Unsafe! The magnitude of the change is less than 1 or greater than 3.
        return false;
    }
    return true;
}

/// Copies a const slice to the heap so it can be modified.
fn cloneSlice(s: []const ?isize) []?isize {
    const h = std.heap.c_allocator.alloc(?isize, s.len) catch unreachable;
    std.mem.copyForwards(?isize, h, s);
    return h;
}

test "recordIsSafe" {
    try std.testing.expect(reportIsSafeWithoutDamper(&[_]?isize{ 7, 6, 4, 2, 1 }));
    try std.testing.expect(!reportIsSafeWithoutDamper(&[_]?isize{ 1, 2, 7, 8, 9 }));
    try std.testing.expect(!reportIsSafeWithoutDamper(&[_]?isize{ 9, 7, 6, 2, 1 }));
    try std.testing.expect(!reportIsSafeWithoutDamper(&[_]?isize{ 1, 3, 2, 4, 5 }));
    try std.testing.expect(!reportIsSafeWithoutDamper(&[_]?isize{ 8, 6, 4, 4, 1 }));
    try std.testing.expect(reportIsSafeWithoutDamper(&[_]?isize{ 1, 3, 6, 7, 9 }));

    try std.testing.expect(reportIsSafeWithoutDamper(&[_]?isize{ 1, null, 2, 4, 5 }));
    try std.testing.expect(reportIsSafeWithoutDamper(&[_]?isize{ 8, 6, null, 4, 1 }));

    try std.testing.expectEqual(null, reportIsSafeWithDamper(cloneSlice(&[_]?isize{ 1, 2, 7, 8, 9 })));
    try std.testing.expectEqual(null, reportIsSafeWithDamper(cloneSlice(&[_]?isize{ 9, 7, 6, 2, 1 })));
    try std.testing.expectEqual(1, reportIsSafeWithDamper(cloneSlice(&[_]?isize{ 1, 3, 2, 4, 5 })));
    try std.testing.expectEqual(2, reportIsSafeWithDamper(cloneSlice(&[_]?isize{ 8, 6, 4, 4, 1 })));
}
