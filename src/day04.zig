const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Missing input file", .{});
        return;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    var allocator = arena.allocator();
    defer arena.deinit();

    var buffer: [1024]u8 = undefined;
    const path = std.mem.span(std.os.argv[1]);
    var reader = try utils.fileByLines(path, &buffer);

    var lines = std.ArrayList([]const u8).init(allocator);
    while (try reader.next()) |line| {
        const buf = try allocator.alloc(u8, line.len);
        @memcpy(buf, line);
        try lines.append(buf);
    }

    const line_slice = try lines.toOwnedSlice();

    std.debug.print("Part 1: {}\n", .{part1(line_slice)});
    std.debug.print("Part 2: {}\n", .{part2(line_slice)});
}

const Point = struct {
    x: isize,
    y: isize,

    pub fn add(l: Point, r: Point) Point {
        return .{
            .x = l.x + r.x,
            .y = l.y + r.y,
        };
    }

    pub fn timesScalar(self: Point, factor: isize) Point {
        return .{
            .x = self.x * factor,
            .y = self.y * factor,
        };
    }
};

const directions: [8]Point = [_]Point{
    .{ .x = -1, .y = 0 }, // West
    .{ .x = -1, .y = -1 }, // North-West
    .{ .x = 0, .y = -1 }, // North
    .{ .x = 1, .y = -1 }, // North-East
    .{ .x = 1, .y = 0 }, // East
    .{ .x = 1, .y = 1 }, // South-East
    .{ .x = 0, .y = 1 }, // South
    .{ .x = -1, .y = 1 }, // South-West
};

fn part1(lines: []const []const u8) usize {
    var count: usize = 0;
    for (0..lines.len) |y| {
        for (0..lines[y].len) |x| {
            if (lines[y][x] != 'X') {
                continue;
            }

            for (directions) |direction| {
                const point = Point{ .x = @intCast(x), .y = @intCast(y) };
                const vector = &[3]Point{
                    Point.add(point, direction.timesScalar(1)),
                    Point.add(point, direction.timesScalar(2)),
                    Point.add(point, direction.timesScalar(3)),
                };
                if (vector_eql(lines, vector, "MAS")) {
                    count += 1;
                }
            }
        }
    }
    return count;
}

test "part1 test" {
    const lines = &[_][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    };
    try std.testing.expectEqual(18, part1(lines));
}

fn part2(lines: []const []const u8) usize {
    var count: usize = 0;
    // We can avoid looking at the first and last lines.
    // Same with the first and last characters.
    for (1..lines.len - 1) |y| {
        for (1..lines[y].len - 1) |x| {
            if (lines[y][x] != 'A') {
                continue;
            }

            // Look for a MAS or SAM going left-to-right
            const ltr = [_]u8{ lines[y - 1][x - 1], lines[y][x], lines[y + 1][x + 1] };
            const rtl = [_]u8{ lines[y + 1][x - 1], lines[y][x], lines[y - 1][x + 1] };
            if ((std.mem.eql(u8, &ltr, "MAS") or std.mem.eql(u8, &ltr, "SAM")) and
                (std.mem.eql(u8, &rtl, "MAS") or std.mem.eql(u8, &rtl, "SAM")))
            {
                count += 1;
            }
        }
    }
    return count;
}

test "part2 test" {
    const lines = &[_][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    };
    try std.testing.expectEqual(9, part2(lines));
}

fn vector_eql(matrix: []const []const u8, vector: []const Point, to: []const u8) bool {
    if (vector.len != to.len) {
        return false;
    }

    for (vector, 0..) |elem, i| {
        if (elem.y < 0 or elem.y >= matrix.len) {
            return false;
        }

        const line = matrix[@intCast(elem.y)];
        if (elem.x < 0 or elem.x >= line.len) {
            return false;
        }

        if (line[@intCast(elem.x)] != to[i]) {
            return false;
        }
    }
    return true;
}
