const std = @import("std");
// const raylib = @import("libs/raylib-zig/lib.zig"); //call .Pkg() with the folder raylib-zig is in relative to project build.zig
const raylib = @import("libs/raylib/build.zig"); //call .Pkg() with the folder raylib-zig is in relative to project build.zig

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

    const zrog = b.addExecutable(
        .{
            .name = "zrog",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        },
    );

    const zecs = b.addExecutable(
        .{
            .name = "zecs",
            .root_source_file = .{ .path = "libs/zecs/src/main.zig" },
            .target = target,
            .optimize = optimize,
        },
    );

    b.installArtifact(zrog);
    b.installArtifact(zecs);

    const zecs_module = b.createModule(.{
        .source_file = .{ .path = "libs/zecs/src/main.zig" },
        .dependencies = &.{},
    });
    zrog.addModule("zecs", zecs_module);

    raylib.addTo(b, zrog, target, optimize);

    const run_cmd = b.addRunArtifact(zrog);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const system_lib = b.option(bool, "system-raylib", "link to preinstalled raylib libraries") orelse false;
    // _ = system_lib;

    // const exe = b.addExecutable(
    //     .{
    //         .name = "zrog",
    //         .root_source_file = .{ .path = "src/main.zig" },
    //         .target = target,
    //         .optimize = optimize,
    //     },
    // );

    // const zecs = b.addExecutable(
    //     .{
    //         .name = "zecs",
    //         .root_source_file = .{ .path = "libs/zecs/src/main.zig" },
    //         .target = target,
    //         .optimize = optimize,
    //     },
    // );
    // const zecs_run = b.addRunArtifact(zecs);
    // // exe.addRun(zecs);

    // // Raylib
    // raylib.addTo(b, exe, target, optimize);

    // // raylib.link(exe, system_lib);
    // // raylib.addAsPackage("raylib", exe);
    // // raylib.math.addAsPackage("raylib-math", exe);

    // // const zecs = std.build.Pkg{
    // //     .name = "zecs",
    // //     .source = .{ .path = "libs/zecs/src/main.zig" },
    // // };
    // // _ = zecs;
    // // _ = b.addRunArtifact(.{
    // //     .name = "zecs",
    // //     .root_source_file = .{ .path = "libs/zecs/src/main.zig" },
    // // });
    // // Zecs
    // // exe.addPackagePath("zecs", "libs/zecs/src/main.zig");
    // const run_cmd = exe.run();

    // const run_step = b.step("run", "run zrog");
    // run_step.dependOn(&run_cmd.step);
    // run_step.dependOn(&zecs_run.step);

    // //tests
    // // const main_tests = b.addTest("src/main.zig");
    // // main_tests.setBuildMode(mode);
    // // const test_step = b.step("test", "Run library tests");
    // // test_step.dependOn(&main_tests.step);
    // // main_tests.addPackagePath("zecs", "libs/zecs/src/main.zig");

    // // raylib.link(main_tests, system_lib);
    // // raylib.addAsPackage("raylib", main_tests);
    // // raylib.math.addAsPackage("raylib-math", main_tests);

    // // const test_step = b.step("test", "Runs the test suite");
    // // const test_suite = b.addTest("src/main.zig");
    // // test_suite.step.dependOn(&run_cmd.step);
    // // test_step.dependOn(&test_suite.step);

    // exe.install();
}

// add this package to exe
// pub fn addTo(b: *std.Build, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, optimize: std.builtin.Mode) void {
//     exe.addAnonymousModule("zecs", .{ .source_file = .{ .path = cwd ++ sep ++ "raylib.zig" } });
//     exe.addIncludePath(.{ .path = dir_raylib });
//     exe.addIncludePath(.{ .path = cwd });
//     const lib = linkThisLibrary(b, target, optimize);
//     const lib_raylib = raylib_build.addRaylib(b, target, optimize, .{});
//     exe.linkLibrary(lib_raylib);
//     exe.linkLibrary(lib);
// }
