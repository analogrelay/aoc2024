const std = @import("std");
const utils = @import("./utils.zig");
const grid = @import("./grid.zig");

const Square = union(enum) {
    wall,
    floor: Footprints,

    const Footprints = packed struct {
        northbound: bool = false,
        eastbound: bool = false,
        southbound: bool = false,
        westbound: bool = false,

        pub fn any(self: @This()) bool {
            return self.northbound or self.eastbound or self.southbound or self.westbound;
        }

        pub fn match(self: *@This(), direction: grid.Direction) bool {
            return switch (direction) {
                .north => self.northbound,
                .east => self.eastbound,
                .south => self.southbound,
                .west => self.westbound,
                else => false,
            };
        }

        pub fn set(self: *@This(), direction: grid.Direction) void {
            switch (direction) {
                .north => self.northbound = true,
                .east => self.eastbound = true,
                .south => self.southbound = true,
                .west => self.westbound = true,
                else => std.debug.panic("Only 4 directions in this grid!", .{}),
            }
        }
    };
};

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Missing input file", .{});
        return;
    }

    const path = std.mem.span(std.os.argv[1]);
    const file = try std.fs.cwd().openFile(path, .{});
    var start_pos: grid.Vector = undefined;
    var map = try parse_input(std.heap.c_allocator, file.reader().any(), &start_pos);

    std.debug.print("Part 1: {}\n", .{part1(&map, start_pos)});
}

fn parse_input(allocator: std.mem.Allocator, file_reader: std.io.AnyReader, start_pos: *grid.Vector) !grid.Grid(Square) {
    var buffer: [1024]u8 = undefined;
    var map = grid.Grid(Square).init(allocator);
    var reader = utils.readByLines(file_reader, &buffer);

    var line_buffer: ?[]Square = null;
    defer if (line_buffer) |b| {
        allocator.free(b);
    };

    var y: usize = 0;
    while (try reader.next()) |line| {
        if (std.mem.indexOfScalar(u8, line, '^')) |x| {
            start_pos.* = grid.Vector{ .x = @intCast(x), .y = @intCast(y) };
        }
        if (line_buffer == null) {
            line_buffer = try allocator.alloc(Square, line.len);
        }
        for (line, 0..) |char, i| {
            line_buffer.?[i] = switch (char) {
                '#' => .wall,
                else => .{ .floor = .{} },
            };
        }
        try map.appendRow(line_buffer.?);
        y += 1;
    }
    return map;
}

fn part1(map: *grid.Grid(Square), start_pos: grid.Vector) usize {
    var walker = map.spawnWalker(start_pos, grid.Direction.north);
    var counter: usize = 0;
    while (walker.next()) |cell| {
        switch (cell.*) {
            .wall => {
                walker.moveBack();
                walker.facing = walker.facing.rotateRight();
            },
            .floor => {
                if (!cell.floor.any()) {
                    cell.floor.set(walker.facing);
                    counter += 1;
                }
            },
        }
    }
    return counter;
}

const TEST_INPUT =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;
test "part1" {
    var stream = std.io.fixedBufferStream(TEST_INPUT);
    var start_pos: grid.Vector = undefined;
    var map = try parse_input(std.testing.allocator, stream.reader().any(), &start_pos);
    defer map.deinit();

    try std.testing.expectEqual(41, part1(&map, start_pos));
}
