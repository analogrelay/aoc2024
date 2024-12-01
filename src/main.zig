const std = @import("std");
const utils = @import("./utils.zig");

pub fn main() !void {
    std.log.info("Advent of Code 2024 - Zig Edition", .{});

    // Parse arguments
    var args = std.process.args();
    var day: ?usize = null;
    var part: ?usize = null;
    var input: ?[:0]const u8 = null;

    // Skip the first argument which is the program name
    _ = args.skip();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            std.log.info("Usage: aoc2024 --day [day] --part [part] [input_path]", .{});
            return;
        } else if (std.mem.eql(u8, arg, "--day")) {
            if (args.next()) |val| {
                day = try std.fmt.parseInt(usize, val, 10);
            } else {
                std.log.err("Missing argument for --day", .{});
                return;
            }
        } else if (std.mem.eql(u8, arg, "--part")) {
            if (args.next()) |val| {
                part = try std.fmt.parseInt(usize, val, 10);
            } else {
                std.log.err("Missing argument for --part", .{});
                return;
            }
        } else {
            if (input == null) {
                input = arg;
            } else {
                std.log.err("Unknown argument: {s}", .{arg});
                return;
            }
        }
    }

    if (day == null) {
        std.log.err("Missing argument --day", .{});
        return;
    }

    if (part == null) {
        std.log.err("Missing argument --part", .{});
        return;
    }

    if (input == null) {
        std.log.err("Missing input path", .{});
        return;
    }

    try runDay(day.?, part.?, input.?);
}

fn runDay(day: usize, part: usize, input_file: [:0]const u8) !void {
    std.log.info("Running Day: {} Part: {} with input file: {s}", .{ day, part, input_file });

    const file = try std.fs.cwd().openFile(input_file, .{
        .mode = std.fs.File.OpenMode.read_only,
    });
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var lines = utils.linesInput(file.reader(), &buffer);
}
