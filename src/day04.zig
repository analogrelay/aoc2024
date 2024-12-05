const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Missing input file", .{});
        return;
    }

    var buffer: [1024]u8 = undefined;
    const path = std.mem.span(std.os.argv[1]);
    var reader = try utils.fileByLines(path, &buffer);

    var lines = std.ArrayList([]const u8).init(std.heap.c_allocator);
    defer lines.deinit();
    while (try reader.next()) |line| {
        try lines.append(line);
    }

    const counts = part1(try lines.toOwnedSlice());
    std.debug.print("Part 1: {}\n", .{counts});
}

const Point = struct {
    x: isize,
    y: isize,

    fn add(l: Point, r: Point) Point {
        return .{
            .x = l.x + r.x,
            .y = l.y + r.y,
        };
    }
};

const direction_vectors: []const [3]Point = &[_][3]Point{
    [_]Point{ .{ .x = -1, .y = 0 }, .{ .x = -2, .y = 0 }, .{ .x = -3, .y = 0 } }, // West
    [_]Point{ .{ .x = -1, .y = -1 }, .{ .x = -2, .y = -2 }, .{ .x = -3, .y = -3 } }, // North-West
    [_]Point{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = -2 }, .{ .x = 0, .y = -3 } }, // North
    [_]Point{ .{ .x = 1, .y = -1 }, .{ .x = 2, .y = -2 }, .{ .x = 3, .y = -3 } }, // North-East
    [_]Point{ .{ .x = 1, .y = 0 }, .{ .x = 2, .y = 0 }, .{ .x = 3, .y = 0 } }, // East
    [_]Point{ .{ .x = 1, .y = 1 }, .{ .x = 2, .y = 2 }, .{ .x = 3, .y = 3 } }, // South-East
    [_]Point{ .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 2 }, .{ .x = 0, .y = 3 } }, // South
    [_]Point{ .{ .x = -1, .y = 1 }, .{ .x = -2, .y = 2 }, .{ .x = -3, .y = 3 } }, // South-West
};

fn part1(lines: []const []const u8) usize {
    var count: usize = 0;
    for (0..lines.len) |y| {
        for (0..lines[y].len) |x| {
            for (direction_vectors) |dir_vec| {
                const vector = &[4]Point{
                    .{ .x = @intCast(x), .y = @intCast(y) },
                    Point.add(dir_vec[0], .{ .x = @intCast(x), .y = @intCast(y) }),
                    Point.add(dir_vec[1], .{ .x = @intCast(x), .y = @intCast(y) }),
                    Point.add(dir_vec[2], .{ .x = @intCast(x), .y = @intCast(y) }),
                };
                if (vector_eql(lines, vector, "XMAS")) {
                    count += 1;
                }
            }
        }
    }
    return count;
}

test "part1 test" {
    const lines = [_][]const u8{
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
    try std.testing.expectEqual(18, part1(&lines));
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
