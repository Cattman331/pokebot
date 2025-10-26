const std = @import("std");
const andy = @import("andy");
const openai = @import("openai");
const config_mod = @import("config");

fn describe(alloc: std.mem.Allocator, api_key: []const u8, model_id: []const u8, path: []const u8) !void {
    const question = "What is in the image?";
    const resp = try openai.chatMulti(alloc, api_key, model_id, question, path);
    if (resp.choices.len > 0) {
        std.debug.print("{s}\n", .{resp.choices[0].message.content});
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const api_key = std.process.getEnvVarOwned(allocator, "OAI_POKEBOT") catch return error.MissingApiKey;
    defer allocator.free(api_key);

    var config_path_owned = std.process.getEnvVarOwned(allocator, "POKEBOT_CONFIG") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => null,
        else => return err,
    };
    defer if (config_path_owned) |path| allocator.free(path);

    const config_path = if (config_path_owned) |path|
        path
    else
        "config/bluestacks.json";

    const config = try config_mod.load(allocator, config_path);
    const model_id = config.openai_model;

    var device = try andy.Andy.init(allocator, .{
        .adb_path = config.adb_path,
        .start_scrcpy = config.start_scrcpy,
        .scrcpy_path = config.scrcpy_path,
        .scrcpy_args = config.scrcpy_args,
        .start_app = config.start_app,
        .device_serial = config.device_serial,
        .connect = config.adb_connect,
        .screen = config.screen,
        .ui_overrides = config.ui_overrides,
    });
    defer device.deinit();

    std.time.sleep(2_000_000_000);

    std.time.sleep(2_000_000_000);
    try device.tapAndCapture(.BattleBtn, "cap_battle.png");
    try describe(allocator, api_key, model_id, "cap_battle.png");

    std.time.sleep(5_000_000_000);
    try device.tapAndCapture(.VersusBtn, "cap_versus.png");

    std.time.sleep(5_000_000_000);
    try device.tapAndCapture(.RandomMatchBtn, "cap_random.png");

    std.time.sleep(5_000_000_000);
    try device.tapAndCapture(.StartMatchBtn, "cap_start.png");
}
