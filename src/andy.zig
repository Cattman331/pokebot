const std = @import("std");
const ui = @import("ui");

pub const Andy = struct {
    allocator: std.mem.Allocator,
    options: Options,
    scrcpy_process: ?std.process.Child = null,

    pub const Options = struct {
        adb_path: []const u8,
        start_scrcpy: bool = false,
        scrcpy_path: ?[]const u8 = null,
        scrcpy_args: []const []const u8 = &[_][]const u8{},
        start_app: ?[]const u8 = null,
        device_serial: ?[]const u8 = null,
        connect: ?Connect = null,
        screen: ui.ScreenSpec,
        ui_overrides: []const ui.Override = &[_]ui.Override{},
    };

    pub const Connect = struct {
        host: []const u8,
        port: u16,
    };

    pub fn init(allocator: std.mem.Allocator, options: Options) !Andy {
        var instance = Andy{
            .allocator = allocator,
            .options = options,
            .scrcpy_process = null,
        };

        try instance.ensureConnection();

        if (options.start_scrcpy) {
            try instance.launchScrcpy();
        }

        return instance;
    }

    pub fn deinit(self: *Andy) void {
        if (self.scrcpy_process) |*proc| {
            _ = proc.kill() catch {};
            _ = proc.wait() catch {};
        }
    }

    fn ensureConnection(self: *Andy) !void {
        if (self.options.connect) |connect| {
            const host_port = try std.fmt.allocPrint(self.allocator, "{s}:{d}", .{ connect.host, connect.port });
            defer self.allocator.free(host_port);
            try self.exec_adb(&.{ "connect", host_port });
        }
    }

    fn launchScrcpy(self: *Andy) !void {
        const path = self.options.scrcpy_path orelse return error.MissingScrcpyPath;

        var argv = std.ArrayList([]const u8).init(self.allocator);
        defer argv.deinit();

        try argv.append(path);

        if (self.options.device_serial) |serial| {
            try argv.appendSlice(&.{ "--serial", serial });
        }

        if (self.options.start_app) |app| {
            try argv.appendSlice(&.{ "--start-app", app });
        }

        for (self.options.scrcpy_args) |arg| {
            try argv.append(arg);
        }

        var child = std.process.Child.init(argv.items, self.allocator);
        child.stdin_behavior = .Pipe;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;

        try child.spawn();
        self.scrcpy_process = child;
    }

    pub fn tap(self: Andy, element: ui.UI) !void {
        const xy = ui.coords(element, self.options.screen, self.options.ui_overrides);
        std.debug.print("\n[tap]: {} @ ({}, {})\n", .{ element, xy[0], xy[1] });
        try self.use_tap(xy[0], xy[1]);
    }

    fn use_tap(self: Andy, x: u16, y: u16) !void {
        const x_str = try std.fmt.allocPrint(self.allocator, "{}", .{x});
        defer self.allocator.free(x_str);
        const y_str = try std.fmt.allocPrint(self.allocator, "{}", .{y});
        defer self.allocator.free(y_str);

        std.time.sleep(100_000_000);

        try self.exec_adb(&.{
            "shell", "input", "tap", x_str, y_str,
        });

        std.time.sleep(100_000_000);
    }

    pub fn swipe(self: Andy, x1: u16, y1: u16, x2: u16, y2: u16) !void {
        const x1_str = try std.fmt.allocPrint(self.allocator, "{}", .{x1});
        defer self.allocator.free(x1_str);
        const y1_str = try std.fmt.allocPrint(self.allocator, "{}", .{y1});
        defer self.allocator.free(y1_str);
        const x2_str = try std.fmt.allocPrint(self.allocator, "{}", .{x2});
        defer self.allocator.free(x2_str);
        const y2_str = try std.fmt.allocPrint(self.allocator, "{}", .{y2});
        defer self.allocator.free(y2_str);

        try self.exec_adb(&.{
            "shell", "input", "swipe", x1_str, y1_str, x2_str, y2_str,
        });
    }

    pub fn screenshot(self: Andy, out_path: []const u8) !void {
        var argv = std.ArrayList([]const u8).init(self.allocator);
        defer argv.deinit();

        try argv.append(self.options.adb_path);

        if (self.options.device_serial) |serial| {
            try argv.appendSlice(&.{ "-s", serial });
        }

        try argv.appendSlice(&.{
            "exec-out",
            "screencap",
            "-p",
        });

        var child = std.process.Child.init(argv.items, self.allocator);

        child.stdin_behavior = .Ignore;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;

        try child.spawn();

        const cwd = std.fs.cwd();
        var file = try cwd.createFile(out_path, .{ .truncate = true });
        defer file.close();

        var buffer: [4096]u8 = undefined;
        var adb_out_file = child.stdout.?;
        while (true) {
            const bytes_read = try adb_out_file.read(&buffer);
            if (bytes_read == 0) break;
            try file.writeAll(buffer[0..bytes_read]);
        }

        const term = try child.wait();
        switch (term) {
            .Exited => |code| {
                if (code != 0) {
                    return error.AdbScreenshotFailed;
                }
            },
            else => {
                return error.AdbScreenshotFailed;
            },
        }
    }

    pub fn tapAndCapture(self: Andy, element: ui.UI, out_path: []const u8) !void {
        try self.tap(element);
        std.time.sleep(2_000_000_000);
        try self.screenshot(out_path);
    }

    fn exec_adb(self: Andy, args: []const []const u8) !void {
        var argv = std.ArrayList([]const u8).init(self.allocator);
        defer argv.deinit();

        try argv.append(self.options.adb_path);

        if (self.options.device_serial) |serial| {
            try argv.appendSlice(&.{ "-s", serial });
        }

        for (args) |arg| {
            try argv.append(arg);
        }

        std.debug.print("[cmd]: ", .{});
        for (argv.items) |arg| {
            std.debug.print("{s} ", .{arg});
        }
        std.debug.print("\n", .{});

        var proc = std.process.Child.init(argv.items, self.allocator);
        proc.stdout_behavior = .Pipe;
        proc.stderr_behavior = .Pipe;

        try proc.spawn();

        const term = try proc.wait();

        if (proc.stdout) |stdout| {
            const stdout_data = try stdout.reader().readAllAlloc(self.allocator, 1024 * 1024);
            defer self.allocator.free(stdout_data);
            if (stdout_data.len > 0) {
                std.debug.print("[stdout]: {s}\n", .{stdout_data});
            }
        }

        if (proc.stderr) |stderr| {
            const stderr_data = try stderr.reader().readAllAlloc(self.allocator, 1024 * 1024);
            defer self.allocator.free(stderr_data);
            if (stderr_data.len > 0) {
                std.debug.print("[stderr]: {s}\n", .{stderr_data});
            }
        }

        switch (term) {
            .Exited => |code| {
                if (code != 0) {
                    std.debug.print("[error]: ADB command failed with exit code {}\n", .{code});
                    return error.AdbCommandFailed;
                }
            },
            else => {
                std.debug.print("[error]: ADB command terminated abnormally\n", .{});
                return error.AdbCommandFailed;
            },
        }
    }
};
