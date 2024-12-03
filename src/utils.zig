const std = @import("std");

pub fn LinesInput(comptime ReaderType: type) type {
    const InputType = struct {
        reader: ReaderType,
        stream: std.io.FixedBufferStream([]u8),

        const Self = @This();

        pub fn next(self: *Self) !?[]const u8 {
            self.stream.reset();
            const writer = self.stream.writer();
            self.reader.streamUntilDelimiter(writer, '\n', null) catch |err| {
                switch (err) {
                    error.EndOfStream => {
                        // The stream contains everything up to the EOF.
                        // If the last line of the file has no newline, this will return that last line.
                        if (self.stream.getWritten().len == 0) {
                            return null;
                        }
                        return self.stream.getWritten();
                    },
                    else => |e| return e,
                }
            };
            return self.stream.getWritten();
        }
    };
    return InputType;
}

pub fn fileToStringAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    return try file.readToEndAlloc(allocator, 4 * 1024 * 1024);
}

pub fn fileByLines(path: []const u8, buffer: []u8) !LinesInput(std.fs.File.Reader) {
    const file = try std.fs.cwd().openFile(path, .{});
    return readByLines(file.reader(), buffer);
}

pub fn readByLines(reader: anytype, buffer: []u8) LinesInput(@TypeOf(reader)) {
    return .{
        .reader = reader,
        .stream = std.io.fixedBufferStream(buffer),
    };
}
