const std = @import("std");
const builtin = @import("builtin");

pub extern "kernel32" fn GetSystemTimePreciseAsFileTime(*std.os.windows.FILETIME) callconv(std.os.windows.WINAPI) void;

// const Days2022 = struct {
//     pub const d01 = @import("./2022/day01.zig");
//     pub const d02 = @import("./2022/day02.zig");
//     pub const d03 = @import("./2022/day03.zig");
//     pub const d04 = @import("./2022/day04.zig");
//     pub const d05 = @import("./2022/day05.zig");
//     pub const d06 = @import("./2022/day06.zig");
//     pub const d07 = @import("./2022/day07.zig");
//     pub const d08 = @import("./2022/day08.zig");
//     pub const d09 = @import("./2022/day09.zig");
//     pub const d10 = @import("./2022/day10.zig");
//     pub const d11 = @import("./2022/day11.zig");
//     pub const d12 = @import("./2022/day12.zig");
//     pub const d13 = @import("./2022/day13.zig");
//     pub const d14 = @import("./2022/day14.zig");
//     pub const d15 = @import("./2022/day15.zig");
// };
// const Days2023 = struct {
//     pub const d01 = @import("./2023/day01.zig");
//     pub const d02 = @import("./2023/day02.zig");
// };
const Days2024 = struct {
    pub const d01 = @import("./2024/day01.zig");
    pub const d02 = @import("./2024/day02.zig");
    pub const d03 = @import("./2024/day03.zig");
    pub const d04 = @import("./2024/day04.zig");
};

const TargetYear = Days2024;
const TARGET_INPUT_DIR = "input/2024";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var inputDir = try std.fs.cwd().openDir(TARGET_INPUT_DIR, .{});
    defer inputDir.close();
    var start: i128 = undefined;
    var stdout = std.io.getStdOut();

    inline for (@typeInfo(TargetYear).Struct.decls) |decl| {
        const dayNumber = comptime std.fmt.parseInt(u8, decl.name[1..], 10) catch undefined;
        const fileName = "day" ++ decl.name[1..] ++ ".txt";
        var arena = std.heap.ArenaAllocator.init(gpa.allocator());
        defer arena.deinit();
        const file = try inputDir.openFile(fileName, .{ .mode = .read_only });
        const buffer = try file.readToEndAlloc(arena.allocator(), std.math.maxInt(usize));
        const module = comptime @field(TargetYear, decl.name);

        const hasPart1 = comptime hasField(module, "part1");
        if (hasPart1) {
            start = nanoTimestamp();
            const result = try module.part1(buffer, arena.allocator());
            const outputFormat = comptime switch (@typeInfo(@TypeOf(result))) {
                .Pointer => |info| switch (info.size) {
                    .Slice => "{s}",
                    else => "{any}",
                },
                else => "{any}",
            };
            const dur = try prettyPrintTimeDiff(nanoTimestamp() - start, arena.allocator());
            try std.fmt.format(stdout.writer(), "Day {d} Part 1 ({s}): " ++ outputFormat ++ "\n", .{ dayNumber, dur, result });
        }

        const hasPart2 = comptime hasField(module, "part2");
        if (hasPart2) {
            start = nanoTimestamp();
            const result = try module.part2(buffer, arena.allocator());
            const outputFormat = comptime switch (@typeInfo(@TypeOf(result))) {
                .Pointer => |info| switch (info.size) {
                    .Slice => "{s}",
                    else => "{any}",
                },
                else => "{any}",
            };
            const dur = try prettyPrintTimeDiff(nanoTimestamp() - start, arena.allocator());
            try std.fmt.format(stdout.writer(), "Day {d} Part 2 ({s}): " ++ outputFormat ++ "\n", .{ dayNumber, dur, result });
        }
    }
}

fn hasField(comptime T: type, comptime name: []const u8) bool {
    for (std.meta.declarations(T)) |decl| {
        if (std.mem.eql(u8, decl.name, name)) {
            return true;
        }
    }
    return false;
}

fn prettyPrintTimeDiff(nanoDiff: i128, allocator: std.mem.Allocator) ![]const u8 {
    var floatDiff = std.math.lossyCast(f64, nanoDiff);

    var output = std.ArrayList(u8).init(allocator);
    const writer = output.writer();

    if (@divFloor(nanoDiff, std.time.ns_per_min) > 0) {
        try std.fmt.format(writer, "{}min ", .{@divFloor(nanoDiff, std.time.ns_per_min)});
        try std.fmt.format(writer, "{d}s", .{@rem(@ceil(floatDiff / std.time.ns_per_s), std.time.s_per_min)});
        return output.toOwnedSlice();
    }

    // Trim number to only have 3 significant bytes
    try std.fmt.format(writer, "{d}", .{floatDiff});

    const exponent = std.math.lossyCast(f64, if (output.items.len > 3) output.items.len - 3 else 0);
    const denominator = std.math.pow(f64, 10, exponent);
    floatDiff = try std.math.divCeil(f64, floatDiff, denominator);
    floatDiff *= denominator;
    output.clearRetainingCapacity();

    if (@divFloor(floatDiff, std.time.ns_per_s) >= 1) {
        try std.fmt.format(writer, "{d}s", .{@ceil(floatDiff / std.time.ns_per_s * 100) / 100});
        return output.toOwnedSlice();
    }
    if (@divFloor(floatDiff, std.time.ns_per_ms) >= 1) {
        try std.fmt.format(writer, "{d}ms", .{@ceil(floatDiff / std.time.ns_per_ms * 100) / 100});
        return output.toOwnedSlice();
    }
    if (@divFloor(floatDiff, std.time.ns_per_us) >= 1) {
        try std.fmt.format(writer, "{d}us", .{@ceil(floatDiff / std.time.ns_per_us * 100) / 100});
        return output.toOwnedSlice();
    } else {
        try std.fmt.format(writer, "{d}ns", .{floatDiff});
    }

    return output.toOwnedSlice();
}

fn nanoTimestamp() i128 {
    if (builtin.os.tag != .windows) {
        return std.time.nanoTimestamp();
    }

    // FileTime has a granularity of 100 nanoseconds and uses the NTFS/Windows epoch,
    // which is 1601-01-01.
    const epoch_adj = std.time.epoch.windows * (std.time.ns_per_s / 100);
    var ft: std.os.windows.FILETIME = undefined;
    GetSystemTimePreciseAsFileTime(&ft);
    const ft64 = (@as(u64, ft.dwHighDateTime) << 32) | ft.dwLowDateTime;
    return @as(i128, @as(i64, @bitCast(ft64)) + epoch_adj) * 100;
}

test "prettyPrint minutes" {
    const result = try prettyPrintTimeDiff(std.time.ns_per_ms * 61100, std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "1min 2s", result);
}

test "prettyPrint seconds" {
    const result = try prettyPrintTimeDiff(std.time.ns_per_ms * 5111, std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "5.12s", result);
}

test "prettyPrint ms" {
    const result = try prettyPrintTimeDiff(std.time.ns_per_us * 15122, std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "15.2ms", result);
}

test "prettyPrint us" {
    const result = try prettyPrintTimeDiff(8555, std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "8.56us", result);
}

test "prettyPrint ns" {
    const result = try prettyPrintTimeDiff(999, std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "999ns", result);
}
