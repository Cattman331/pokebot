const std = @import("std");

pub const UI = enum {
    StartScreenTap,
    BattleBtn,
    VersusBtn,
    RandomMatchBtn,
    StartMatchBtn,
};

pub const Override = struct {
    element: UI,
    coords: [2]u16,
};

pub const ScreenSpec = struct {
    width: u32,
    height: u32,
    base_width: u32 = 1080,
    base_height: u32 = 2340,

    pub fn scale(self: ScreenSpec, point: [2]u16) [2]u16 {
        const x_scaled = (@as(u64, point[0]) * @as(u64, self.width) + @as(u64, self.base_width) / 2) / @as(u64, self.base_width);
        const y_scaled = (@as(u64, point[1]) * @as(u64, self.height) + @as(u64, self.base_height) / 2) / @as(u64, self.base_height);

        const max_u16 = @as(u64, std.math.maxInt(u16));
        const clamped_x = if (x_scaled > max_u16) max_u16 else x_scaled;
        const clamped_y = if (y_scaled > max_u16) max_u16 else y_scaled;

        return .{
            @intCast(u16, clamped_x),
            @intCast(u16, clamped_y),
        };
    }
};

pub fn coords(element: UI, screen: ScreenSpec, overrides: []const Override) [2]u16 {
    for (overrides) |override| {
        if (override.element == element) {
            return override.coords;
        }
    }

    return screen.scale(baseCoords(element));
}

pub fn parseName(name: []const u8) ?UI {
    return std.meta.stringToEnum(UI, name);
}

fn baseCoords(element: UI) [2]u16 {
    return switch (element) {
        .StartScreenTap => .{ 543, 2067 },
        .BattleBtn => .{ 719, 2288 },
        .VersusBtn => .{ 260, 1912 },
        .RandomMatchBtn => .{ 739, 1947 },
        .StartMatchBtn => .{ 540, 1916 },
    };
}
