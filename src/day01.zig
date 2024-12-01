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

    var leftList = std.ArrayList(isize).init(std.heap.c_allocator);
    var rightList = std.ArrayList(isize).init(std.heap.c_allocator);

    while (try lines.next()) |line| {
        var splat = std.mem.splitSequence(u8, line, "   ");
        const left = splat.next() orelse return error.InvalidInput;
        const right = splat.next() orelse return error.InvalidInput;
        try leftList.append(try std.fmt.parseInt(isize, left, 10));
        try rightList.append(try std.fmt.parseInt(isize, right, 10));
    }

    const leftSlice = try leftList.toOwnedSlice();
    const rightSlice = try rightList.toOwnedSlice();
    std.mem.sort(isize, leftSlice, {}, std.sort.asc(isize));
    std.mem.sort(isize, rightSlice, {}, std.sort.asc(isize));

    try part1(leftSlice, rightSlice);
    try part2(leftSlice, rightSlice);
}

pub fn part1(leftSlice: []isize, rightSlice: []isize) !void {
    var distanceSum: usize = 0;
    for (leftSlice, rightSlice) |left, right| {
        distanceSum += @abs(left - right);
    }

    std.log.info("Part 1 result: {d}", .{distanceSum});
}

pub fn part2(leftSlice: []isize, rightSlice: []isize) !void {
    var similarity: usize = 0;
    for (leftSlice) |left| {
        var score: usize = 0;
        // Find the first instance of this in the sorted right slice
        const first_index = std.mem.indexOfScalar(isize, rightSlice, left);

        // If it was found, we can just seek until an entry that doesn't match, because the list is sorted.
        if (first_index) |first| {
            var current = first;
            while (rightSlice[current] == left) {
                score += 1;
                current += 1;
            }
        }

        const val: usize = @intCast(left);
        similarity += val * score;
    }

    std.log.info("Part 2 result: {d}", .{similarity});
}
