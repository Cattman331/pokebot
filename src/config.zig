const std = @import("std");
const ui = @import("ui");

pub const AdbConnect = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 5555,
};

pub const Config = struct {
    adb_path: []const u8,
    start_scrcpy: bool,
    scrcpy_path: ?[]const u8,
    scrcpy_args: []const []const u8,
    start_app: ?[]const u8,
    openai_model: []const u8,
    device_serial: ?[]const u8,
    adb_connect: ?AdbConnect,
    screen: ui.ScreenSpec,
    ui_overrides: []const ui.Override,
};

const RawConfig = struct {
    const String = []const u8;

    adb_path: []const u8,
    start_scrcpy: bool = false,
    scrcpy_path: ?[]const u8 = null,
    scrcpy_args: ?[]const String = null,
    start_app: ?[]const u8 = null,
    openai_model: []const u8 = "gpt-4o",
    device: RawDevice = .{},
    screen: RawScreen,
    ui_overrides: ?[]const RawOverride = null,
};

const RawDevice = struct {
    serial: ?[]const u8 = null,
    connect: ?AdbConnect = null,
};

const RawScreen = struct {
    width: u32,
    height: u32,
    base_width: u32 = 1080,
    base_height: u32 = 2340,
};

const RawOverride = struct {
    element: []const u8,
    x: u16,
    y: u16,
};

pub fn load(allocator: std.mem.Allocator, path: []const u8) !Config {
    const data = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(usize));
    defer allocator.free(data);

    const raw = try std.json.parseFromSliceLeaky(RawConfig, allocator, data, .{
        .ignore_unknown_fields = true,
    });

    const scrcpy_args = raw.scrcpy_args orelse &[_][]const u8{};

    var overrides_list: []const ui.Override = &[_]ui.Override{};
    if (raw.ui_overrides) |items| {
        var overrides = try allocator.alloc(ui.Override, items.len);
        for (items, 0..) |entry, idx| {
            const element = ui.parseName(entry.element) orelse return error.UnknownUIElement;
            overrides[idx] = ui.Override{
                .element = element,
                .coords = .{ entry.x, entry.y },
            };
        }
        overrides_list = overrides;
    }

    const screen = ui.ScreenSpec{
        .width = raw.screen.width,
        .height = raw.screen.height,
        .base_width = raw.screen.base_width,
        .base_height = raw.screen.base_height,
    };

    return Config{
        .adb_path = raw.adb_path,
        .start_scrcpy = raw.start_scrcpy,
        .scrcpy_path = raw.scrcpy_path,
        .scrcpy_args = scrcpy_args,
        .start_app = raw.start_app,
        .openai_model = raw.openai_model,
        .device_serial = raw.device.serial,
        .adb_connect = raw.device.connect,
        .screen = screen,
        .ui_overrides = overrides_list,
    };
}
