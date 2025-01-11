const std = @import("std");

pub fn lcm(a: anytype, b: anytype) @TypeOf(a, b) {
    // only unsigned integers are allowed and both must be positive
    comptime switch (@typeInfo(@TypeOf(a, b))) {
        .Int => |int| std.debug.assert(int.signedness == .unsigned),
        .ComptimeInt => {
            std.debug.assert(a > 0);
            std.debug.assert(b > 0);
        },
        else => unreachable,
    };
    std.debug.assert(a != 0 and b != 0);

    const gcd: @TypeOf(a, b) = std.math.gcd(a, b);
    return a / gcd * b;
}

test "LCM" {
    const a: u32 = 10;
    const b: u32 = 35;
    try std.testing.expectEqual(@as(u32, 70), lcm(a, b));
}
