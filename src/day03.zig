const std = @import("std");
const utils = @import("./utils.zig");

const Instruction = union(enum) {
    mul: Multiply,
    do,
    dont,

    const Self = @This();

    const Multiply = struct {
        x: usize,
        y: usize,

        fn parse(in: []const u8, consumed: *usize) ?Multiply {
            var buf = in;
            if (buf.len < 4 or !std.mem.eql(u8, buf[0..4], "mul(")) {
                consumed.* = 1;
                return null;
            }

            buf = buf[4..];
            consumed.* = 4;

            const comma_index = std.mem.indexOfAny(u8, buf, ",)");
            if (comma_index == null or buf[comma_index.?] == ')') {
                // No comma found (or we found the ')' first)
                return null;
            }

            const x = std.fmt.parseInt(usize, buf[0..comma_index.?], 10) catch return null;

            buf = buf[(comma_index.? + 1)..];
            consumed.* += comma_index.? + 1;
            const rparen_index = std.mem.indexOfScalar(u8, buf, ')');
            if (rparen_index == null) {
                // No ')' found
                return null;
            }

            const y = std.fmt.parseInt(usize, buf[0..rparen_index.?], 10) catch return null;

            consumed.* += rparen_index.? + 1;
            return .{ .x = x, .y = y };
        }
    };

    fn parse(in: []const u8, consumed: *usize) ?Instruction {
        if (std.mem.startsWith(u8, in, "do()")) {
            consumed.* = 4;
            return .do;
        }
        if (std.mem.startsWith(u8, in, "don't()")) {
            consumed.* = 7;
            return .dont;
        }
        if (Self.Multiply.parse(in, consumed)) |mul| {
            return .{ .mul = mul };
        }
        return null;
    }
};

test "missing comma" {
    var consumed: usize = 0;
    const inst = Instruction.parse("mul(mul)", &consumed);
    try std.testing.expectEqual(null, inst);
    try std.testing.expectEqual(4, consumed);
}

test "missing rparen" {
    var consumed: usize = 0;
    const inst = Instruction.parse("mul(mul", &consumed);
    try std.testing.expectEqual(null, inst);
    try std.testing.expectEqual(4, consumed);
}

test "invalid numbers" {
    var consumed: usize = 0;
    var buffer: []const u8 = "mul(mul(4,2),b)";
    var inst = Instruction.parse(buffer, &consumed);
    try std.testing.expectEqual(null, inst);
    try std.testing.expectEqual(4, consumed);

    buffer = buffer[consumed..];
    inst = Instruction.parse(buffer, &consumed);
    try std.testing.expectEqual(Instruction{ .mul = .{ .x = 4, .y = 2 } }, inst);
    try std.testing.expectEqual(8, consumed);
}

test "valid 1" {
    var consumed: usize = 0;
    const inst = Instruction.parse("mul(12345,67890)", &consumed);
    try std.testing.expectEqual(Instruction{ .mul = .{ .x = 12345, .y = 67890 } }, inst);
    try std.testing.expectEqual(16, consumed);
}

test "valid 2" {
    var consumed: usize = 0;
    const inst = Instruction.parse("mul(4,2)", &consumed);
    try std.testing.expectEqual(Instruction{ .mul = .{ .x = 4, .y = 2 } }, inst);
    try std.testing.expectEqual(8, consumed);
}

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Missing input file", .{});
        return;
    }

    const path = std.mem.span(std.os.argv[1]);
    const memory = try utils.fileToStringAlloc(std.heap.c_allocator, path);
    defer std.heap.c_allocator.free(memory);

    const part1_result = run_program(memory, true);
    std.debug.print("Part 1: {}\n", .{part1_result});
    const part2_result = run_program(memory, false);
    std.debug.print("Part 2: {}\n", .{part2_result});
}

pub fn run_program(memory: []const u8, always_enabled: bool) usize {
    var buf = memory;
    var total: usize = 0;
    var enabled = true;
    while (buf.len > 0) {
        var consumed: usize = 0;
        if (Instruction.parse(buf, &consumed)) |inst| {
            switch (inst) {
                .do => enabled = true,
                .dont => enabled = false,
                .mul => |m| if (enabled or always_enabled) {
                    total += m.x * m.y;
                },
            }
        }
        buf = buf[consumed..];
    }
    return total;
}

test {
    try std.testing.expectEqual(161, run_program("xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))", true));
    try std.testing.expectEqual(48, run_program("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))", false));
}
