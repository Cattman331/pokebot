const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create modules for our source files
    const ui_mod = b.createModule(.{
        .root_source_file = b.path("src/ui.zig"),
        .target = target,
        .optimize = optimize,
    });

    const config_mod = b.createModule(.{
        .root_source_file = b.path("src/config.zig"),
        .target = target,
        .optimize = optimize,
    });
    config_mod.addImport("ui", ui_mod);

    const openai_mod = b.createModule(.{
        .root_source_file = b.path("src/openai.zig"),
        .target = target,
        .optimize = optimize,
    });

    const andy_mod = b.createModule(.{
        .root_source_file = b.path("src/andy.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Andy depends on ui
    andy_mod.addImport("ui", ui_mod);

    // Main executable module
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main depends on andy and openai
    exe_mod.addImport("andy", andy_mod);
    exe_mod.addImport("openai", openai_mod);
    exe_mod.addImport("config", config_mod);

    const exe = b.addExecutable(.{
        .name = "pokebot",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Unit tests
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
