const std = @import("std");
const Builder = std.build.Builder;
const raylib = @import("libs/raylib-zig/lib.zig"); //call .Pkg() with the folder raylib-zig is in relative to project build.zig

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const system_lib = b.option(bool, "system-raylib", "link to preinstalled raylib libraries") orelse false;

    const exe = b.addExecutable("zrog", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(target);

    // Raylib
    raylib.link(exe, system_lib);
    raylib.addAsPackage("raylib", exe);
    raylib.math.addAsPackage("raylib-math", exe);

    // Zecs
    exe.addPackagePath("zecs", "libs/zecs/src/main.zig");
    const run_cmd = exe.run();
    const run_step = b.step("run", "run zrog");
    run_step.dependOn(&run_cmd.step);

    //tests
    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    main_tests.addPackagePath("zecs", "libs/zecs/src/main.zig");
    raylib.link(main_tests, system_lib);
    raylib.addAsPackage("raylib", main_tests);
    raylib.math.addAsPackage("raylib-math", main_tests);

    // const test_step = b.step("test", "Runs the test suite");
    // const test_suite = b.addTest("src/main.zig");
    // test_suite.step.dependOn(&run_cmd.step);
    // test_step.dependOn(&test_suite.step);

    exe.install();
}
