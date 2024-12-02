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

    var left_list = std.ArrayList(isize).init(std.heap.c_allocator);
    var right_list = std.ArrayList(isize).init(std.heap.c_allocator);

    while (try lines.next()) |line| {
        var splat = std.mem.splitSequence(u8, line, "   ");
        const left = splat.next() orelse return error.InvalidInput;
        const right = splat.next() orelse return error.InvalidInput;
        try left_list.append(try std.fmt.parseInt(isize, left, 10));
        try right_list.append(try std.fmt.parseInt(isize, right, 10));
    }

    const left_slice = try left_list.toOwnedSlice();
    const right_slice = try right_list.toOwnedSlice();
    std.mem.sort(isize, left_slice, {}, std.sort.asc(isize));
    std.mem.sort(isize, right_slice, {}, std.sort.asc(isize));

    try part1(left_slice, right_slice);
    try part2(left_slice, right_slice);
}

pub fn part1(left: []isize, right: []isize) !void {
    var distanceSum: usize = 0;
    for (left, right) |left_val, right_val| {
        distanceSum += @abs(left_val - right_val);
    }

    std.log.info("Part 1 result: {d}", .{distanceSum});
}

pub fn part2(left: []isize, right: []isize) !void {
    var left_index: usize = 0;
    var right_index: usize = 0;
    var similarity: isize = 0;
    while (left_index < left.len and right_index < right.len) {
        const left_val = left[left_index];

        // Advance right index until it's greater than or equal to the candidate
        while (right_index < right.len and right[right_index] < left_val) {
            right_index += 1;
        }

        // Compute the score for this candidate by counting the number of times it appears in the right
        var count: isize = 0;
        while (right_index < right.len and right[right_index] == left_val) {
            count += 1;
            right_index += 1;
        }

        // Now, move to the next unique value on the left
        while (left_index < left.len and left[left_index] == left_val) {
            // Each time we advance, we add the score again
            similarity += left_val * count;
            left_index += 1;
        }
    }

    std.log.info("Part 2 result: {d}", .{similarity});
}
