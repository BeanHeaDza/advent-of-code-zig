const std = @import("std");
const assert = std.debug.assert;
const Hand = struct {
    cards: []const u8,
    bid: u32,
    value: u64,
};

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var hands = std.ArrayList(Hand).init(allocator);
    defer hands.deinit();
    while (lines.next()) |line| {
        var iter = std.mem.splitScalar(u8, line, ' ');
        const hand = iter.first();
        const bid = try std.fmt.parseInt(u32, iter.next().?, 10);
        try hands.append(Hand{ .cards = hand, .bid = bid, .value = try getValue1(hand, "23456789TJQKA") });
    }
    std.sort.heap(Hand, hands.items, {}, sortHand);

    var answer: u32 = 0;
    for (hands.items, 1..) |hand, rank| {
        const temp: u32 = @intCast(rank);
        answer += hand.bid * temp;
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var hands = std.ArrayList(Hand).init(allocator);
    defer hands.deinit();
    while (lines.next()) |line| {
        var iter = std.mem.splitScalar(u8, line, ' ');
        const hand = iter.first();
        const bid = try std.fmt.parseInt(u32, iter.next().?, 10);
        try hands.append(Hand{ .cards = hand, .bid = bid, .value = try getValue2(hand, "J23456789TQKA") });
    }
    std.sort.heap(Hand, hands.items, {}, sortHand);

    var answer: u32 = 0;
    for (hands.items, 1..) |hand, rank| {
        const temp: u32 = @intCast(rank);
        answer += hand.bid * temp;
    }

    return answer;
}

fn sortHand(context: void, a: Hand, b: Hand) bool {
    return std.sort.asc(u64)(context, a.value, b.value);
}

fn getValue1(hand: []const u8, ascCardValue: []const u8) !u64 {
    assert(hand.len == 5);
    const handMultiplier = std.math.pow(u64, ascCardValue.len, 5);
    var buffer = [1]u8{0} ** 48;
    var value: u64 = 0;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var grouping = std.AutoHashMap(u8, u8).init(fba.allocator());
    try grouping.ensureTotalCapacity(5);
    for (hand, 0..) |card, i| {
        value += std.math.pow(u64, ascCardValue.len, 4 - i) * std.mem.indexOfScalar(u8, ascCardValue, card).?;
        const count = try grouping.getOrPutValue(card, 0);
        count.value_ptr.* += 1;
    }
    var counts = [1]u8{0} ** 5;

    var groupIter = grouping.iterator();
    var i: usize = 0;
    while (groupIter.next()) |v| {
        counts[i] = v.value_ptr.*;
        i += 1;
    }
    std.sort.heap(u8, &counts, {}, std.sort.desc(u8));
    if (counts[0] == 5) {
        value += handMultiplier * 6;
    } else if (counts[0] == 4) {
        value += handMultiplier * 5;
    } else if (counts[0] == 3 and counts[1] == 2) {
        value += handMultiplier * 4;
    } else if (counts[0] == 3) {
        value += handMultiplier * 3;
    } else if (counts[0] == 2 and counts[1] == 2) {
        value += handMultiplier * 2;
    } else if (counts[0] == 2) {
        value += handMultiplier;
    }

    return value;
}

fn getValue2(hand: []const u8, ascCardValue: []const u8) !u64 {
    assert(hand.len == 5);
    const handMultiplier = std.math.pow(u64, ascCardValue.len, 5);
    var buffer = [1]u8{0} ** 48;
    var value: u64 = 0;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var grouping = std.AutoHashMap(u8, u8).init(fba.allocator());
    try grouping.ensureTotalCapacity(5);
    for (hand, 0..) |card, i| {
        value += std.math.pow(u64, ascCardValue.len, 4 - i) * std.mem.indexOfScalar(u8, ascCardValue, card).?;
        const count = try grouping.getOrPutValue(card, 0);
        count.value_ptr.* += 1;
    }
    var counts = [1]u8{0} ** 5;
    var jokers: u8 = 0;

    var groupIter = grouping.iterator();
    var i: usize = 0;
    while (groupIter.next()) |v| {
        if (v.key_ptr.* == 'J') {
            jokers = v.value_ptr.*;
        } else {
            counts[i] = v.value_ptr.*;
            i += 1;
        }
    }
    std.sort.heap(u8, &counts, {}, std.sort.desc(u8));
    if (counts[0] + jokers == 5) {
        value += handMultiplier * 6;
    } else if (counts[0] + jokers == 4) {
        value += handMultiplier * 5;
    } else if ((counts[0] == 3 and counts[1] == 2) or (jokers == 1 and counts[1] == 2)) {
        value += handMultiplier * 4;
    } else if (counts[0] + jokers == 3) {
        value += handMultiplier * 3;
    } else if (counts[0] == 2 and counts[1] == 2) {
        value += handMultiplier * 2;
    } else if (counts[0] == 2 or jokers == 1) {
        value += handMultiplier;
    }

    return value;
}

fn asc(context: void, a: u64, b: u64) bool {
    return std.sort.asc(u64)(context, a, b);
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 6440), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 5905), result);
}

const testInput =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
;
