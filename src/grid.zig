const std = @import("std");
const builtin = @import("builtin");

pub const Direction = enum(u3) {
    north = 0,
    northEast = 1,
    east = 2,
    southEast = 3,
    south = 4,
    southWest = 5,
    west = 6,
    northWest = 7,

    pub const All: [8]Direction = blk: {
        const typ = @typeInfo(Direction);
        var values: [8]Direction = undefined;
        for (typ.Enum.fields, 0..) |field, i| {
            values[i] = field.value;
        }
        break :blk values;
    };

    pub fn vector(self: Direction) Vector {
        return switch (self) {
            .north => .{ .x = 0, .y = -1 },
            .northEast => .{ .x = 1, .y = -1 },
            .east => .{ .x = 1, .y = 0 },
            .southEast => .{ .x = 1, .y = 1 },
            .south => .{ .x = 0, .y = 1 },
            .southWest => .{ .x = -1, .y = 1 },
            .west => .{ .x = -1, .y = 0 },
            .northWest => .{ .x = -1, .y = -1 },
        };
    }

    pub fn rotateRight(self: Direction) Direction {
        return switch (self) {
            .north => .east,
            .northEast => .southEast,
            .east => .south,
            .southEast => .southWest,
            .south => .west,
            .southWest => .northWest,
            .west => .north,
            .northWest => .northEast,
        };
    }
};

pub const Vector = struct {
    x: isize = 0,
    y: isize = 0,

    pub fn eql(l: Vector, r: Vector) bool {
        return l.x == r.x and l.y == r.y;
    }

    pub fn add(self: Vector, r: Vector) Vector {
        return .{
            .x = self.x + r.x,
            .y = self.y + r.y,
        };
    }

    pub fn subtract(self: Vector, r: Vector) Vector {
        return .{
            .x = self.x - r.x,
            .y = self.y - r.y,
        };
    }

    pub fn manhattanDistance(self: Vector, other: Vector) usize {
        return @abs(other.x - self.x) + @abs(other.y - self.y);
    }

    pub fn timesScalar(self: Vector, factor: isize) Vector {
        return .{
            .x = self.x * factor,
            .y = self.y * factor,
        };
    }

    pub fn format(value: Vector, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("(");
        try std.fmt.formatInt(value.x, 10, .lower, options, writer);
        try writer.writeAll(", ");
        try std.fmt.formatInt(value.y, 10, .lower, options, writer);
        try writer.writeAll(")");
    }
};

pub fn GridWalker(comptime ElementType: type) type {
    return struct {
        grid: *Grid(ElementType),
        position: Vector,
        facing: Direction,

        const Self = @This();

        pub fn init(grid: *Grid(ElementType), position: Vector, facing: Direction) Self {
            return .{
                .grid = grid,
                .position = position,
                .facing = facing,
            };
        }

        pub fn moveBack(self: *Self) void {
            self.position = self.position.subtract(self.facing.vector());
        }

        pub fn next(self: *Self) ?*ElementType {
            const ptr = self.grid.getPtr(self.position);
            self.position = self.position.add(self.facing.vector());
            return ptr;
        }
    };
}

pub fn Grid(comptime ElementType: type) type {
    return struct {
        rows: std.ArrayList(std.ArrayList(ElementType)),
        arena: std.heap.ArenaAllocator,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            var arena = std.heap.ArenaAllocator.init(allocator);
            const arena_allocator = arena.allocator();
            const rows = std.ArrayList(std.ArrayList(ElementType)).init(arena_allocator);
            return .{
                .rows = rows,
                .arena = arena,
                .allocator = arena_allocator,
            };
        }

        pub fn deinit(self: Self) void {
            // Deallocates everything we've allocated.
            self.arena.deinit();
        }

        pub fn appendRow(self: *Self, row: []const ElementType) !void {
            var list = try std.ArrayList(ElementType).initCapacity(self.allocator, row.len);
            try list.appendSlice(row);
            try self.rows.append(list);
        }

        pub fn spawnWalker(self: *Self, at: Vector, facing: Direction) GridWalker(ElementType) {
            return GridWalker(ElementType).init(self, at, facing);
        }

        pub fn clone(self: *const Self, allocator: std.mem.Allocator) Self {
            var new_grid = Self.init(allocator);
            for (self.rows.items) |row| {
                new_grid.appendRow(row.items);
            }
            return new_grid;
        }

        pub fn print(self: *const Self, writer: std.io.AnyWriter) !void {
            for (self.rows.items) |row| {
                for (row.items) |cell| {
                    const fmt = comptime switch (ElementType) {
                        u8 => "{c}",
                        else => "{}",
                    };
                    try std.fmt.format(writer, fmt, .{cell});
                }
                try writer.writeAll("\n");
            }
        }

        pub fn getPtr(self: *const Self, pos: Vector) ?*ElementType {
            if (pos.y < 0 or pos.y >= self.rows.items.len) {
                return null;
            }

            if (pos.x < 0 or pos.x >= self.rows.items[@intCast(pos.y)].items.len) {
                return null;
            }

            return &self.rows.items[@intCast(pos.y)].items[@intCast(pos.x)];
        }

        pub fn get(self: *const Self, pos: Vector) ?ElementType {
            if (self.getPtr(pos)) |ptr| {
                return ptr.*;
            }
            return null;
        }

        pub fn set(self: *Self, pos: Vector, value: ElementType) bool {
            if (pos.y < 0 or pos.y >= self.rows.items.len) {
                return false;
            }

            if (pos.x < 0 or pos.x >= self.rows.items[@intCast(pos.y)].items.len) {
                return false;
            }

            self.rows.items[@intCast(pos.y)].items[@intCast(pos.x)] = value;
            return true;
        }
    };
}
