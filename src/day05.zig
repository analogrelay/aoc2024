const std = @import("std");
const utils = @import("./utils.zig");

const RuleSet = struct {
    rules: []const Rule,

    pub fn has(self: *@This(), predecessor: usize, successor: usize) bool {
        for (self.rules) |rule| {
            if (rule.before == predecessor and rule.after == successor) {
                return true;
            }
        }
        return false;
    }
};

const Rule = struct {
    before: usize,
    after: usize,

    fn parse(in: []const u8) !Rule {
        var splat = std.mem.tokenizeScalar(u8, in, '|');
        const before = try std.fmt.parseInt(usize, splat.next() orelse return error.InvalidRule, 10);
        const after = try std.fmt.parseInt(usize, splat.next() orelse return error.InvalidRule, 10);
        return .{
            .before = before,
            .after = after,
        };
    }
};

const Update = struct {
    pages: []usize,

    fn parse(allocator: std.mem.Allocator, in: []const u8) !Update {
        var splat = std.mem.tokenizeScalar(u8, in, ',');
        var pages = std.ArrayList(usize).init(allocator);
        while (splat.next()) |splot| {
            try pages.append(try std.fmt.parseInt(usize, splot, 10));
        }
        return .{
            .pages = try pages.toOwnedSlice(),
        };
    }
};

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Missing input file", .{});
        return;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const path = std.mem.span(std.os.argv[1]);
    const file = try std.fs.cwd().openFile(path, .{});

    var rule_set: RuleSet = undefined;
    var updates: []Update = undefined;
    try parse_input(allocator, file.reader().any(), &rule_set, &updates);

    std.debug.print("Part 1: {}\n", .{try part1(&rule_set, updates)});
    std.debug.print("Part 2: {}\n", .{try part2(&rule_set, updates)});
}

fn parse_input(allocator: std.mem.Allocator, file_reader: std.io.AnyReader, rule_set: *RuleSet, updates: *[]Update) !void {
    var buffer: [1024]u8 = undefined;
    var reader = utils.readByLines(file_reader, &buffer);

    var rules = std.ArrayList(Rule).init(allocator);
    var update_list = std.ArrayList(Update).init(allocator);
    var reading_rules = true;
    while (try reader.next()) |line| {
        if (reading_rules) {
            if (line.len == 0) {
                reading_rules = false;
            } else {
                try rules.append(try Rule.parse(line));
            }
        } else {
            try update_list.append(try Update.parse(allocator, line));
        }
    }

    rule_set.* = .{ .rules = rules.items };
    updates.* = update_list.items;
}

pub fn part1(rules: *RuleSet, updates: []const Update) !usize {
    var sum: usize = 0;
    for (updates) |update| {
        if (is_valid(rules, &update)) {
            const middle = update.pages.len / 2;
            sum += update.pages[middle];
        }
    }
    return sum;
}

const TEST_CONTENT =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test "part1" {
    var stream = std.io.fixedBufferStream(TEST_CONTENT);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var rule_set: RuleSet = undefined;
    var updates: []Update = undefined;
    try parse_input(allocator, stream.reader().any(), &rule_set, &updates);

    try std.testing.expectEqual(143, part1(&rule_set, updates));
}

pub fn part2(rules: *RuleSet, updates: []Update) !usize {
    var sum: usize = 0;
    for (updates) |update| {
        if (!is_valid(rules, &update)) {
            repair(rules, update.pages);
            const middle = update.pages.len / 2;
            sum += update.pages[middle];
        }
    }
    return sum;
}

test "part2" {
    var stream = std.io.fixedBufferStream(TEST_CONTENT);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var rule_set: RuleSet = undefined;
    var updates: []Update = undefined;
    try parse_input(allocator, stream.reader().any(), &rule_set, &updates);

    try std.testing.expectEqual(123, part2(&rule_set, updates));
}

fn repair(rules: *RuleSet, pages: []usize) void {
    if (pages.len == 1) {
        return;
    }

    // Find the first page for this update, by looking for the one which has all other pages after it
    var candidate: ?usize = null;
    outer: for (0..pages.len) |i| {
        for (0..pages.len) |j| {
            if (i == j) {
                // We're looking at ourselves ;)
                continue;
            }

            if (!rules.has(pages[i], pages[j])) {
                continue :outer;
            }
        }
        // If we got here, we found our candidate
        candidate = i;
        break;
    }

    // Now that we have our candidate, swap it in to place and continue with the remaining slice
    if (candidate != 0) {
        std.mem.swap(usize, &pages[0], &pages[candidate.?]);
    }
    repair(rules, pages[1..]);
}

fn is_valid(rules: *RuleSet, update: *const Update) bool {
    for (0..update.pages.len) |i| {
        const current = update.pages[i];
        // Scan back to ensure all the numbers before us have rules saying they should be before us.
        for (0..i) |predecessor| {
            if (!rules.has(update.pages[predecessor], current)) {
                return false;
            }
        }

        // And scan forward to ensure all the numbers after us have rules saying they should be after us.
        for (i + 1..update.pages.len) |successor| {
            if (!rules.has(current, update.pages[successor])) {
                return false;
            }
        }
    }

    // All rules check out
    return true;
}
