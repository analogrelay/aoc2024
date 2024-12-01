const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const install_all = b.step("install_all", "Install all days");

    inline for (0..26) |day| {
        const day_name = b.fmt("day{:0>2}", .{day});
        const exe_name = b.fmt("aoc2024-{s}", .{day_name});
        const src_name = b.fmt("src/{s}.zig", .{day_name});
        const src_path = b.path(src_name);

        const day_exe = b.addExecutable(.{
            .name = exe_name,
            .root_source_file = src_path,
            .target = target,
            .optimize = optimize,
        });
        const install_cmd = b.addInstallArtifact(day_exe, .{});
        const build_test = b.addTest(.{
            .root_source_file = src_path,
            .target = target,
            .optimize = optimize,
        });

        const run_test = b.addRunArtifact(build_test);

        {
            const step_key = b.fmt("install_{s}", .{day_name});
            const step_desc = b.fmt("Install {s}", .{exe_name});
            const install_step = b.step(step_key, step_desc);
            install_step.dependOn(&install_cmd.step);
            install_all.dependOn(&install_cmd.step);
        }

        {
            const step_key = b.fmt("test_{s}", .{day_name});
            const step_desc = b.fmt("Test {s}", .{exe_name});
            const test_step = b.step(step_key, step_desc);
            test_step.dependOn(&run_test.step);
        }

        const run_cmd = b.addRunArtifact(day_exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_desc = b.fmt("Run {s}", .{day_name});
        const run_step = b.step(day_name, run_desc);
        run_step.dependOn(&run_cmd.step);
    }
}
