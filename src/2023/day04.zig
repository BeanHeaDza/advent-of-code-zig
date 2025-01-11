const std = @import("std");

const NUMBERS = "0123456789";

const Card = struct {
    number: u32,
    winningNumbers: std.ArrayList(u32),
    myNumbers: std.ArrayList(u32),
    copies: u32,

    pub fn init(line: []const u8, allocator: std.mem.Allocator) !Card {
        var split = std.mem.splitAny(u8, line, " :");
        _ = split.next(); // Card
        while (split.peek().?.len == 0) {
            _ = split.next();
        }
        const number = try std.fmt.parseInt(u32, split.next() orelse return error.NoCardNumber, 10);
        _ = split.next(); // spot between colon after card number and space
        var winningNumbers = std.ArrayList(u32).init(allocator);
        errdefer winningNumbers.deinit();
        var myNumbers = std.ArrayList(u32).init(allocator);
        errdefer myNumbers.deinit();
        var currentList = &winningNumbers;
        while (split.next()) |text| {
            if (text.len == 0) {
                continue;
            } else if (text[0] == '|') {
                currentList = &myNumbers;
                continue;
            }

            try currentList.append(try std.fmt.parseInt(u32, text, 10));
        }

        return .{
            .number = number,
            .winningNumbers = winningNumbers,
            .myNumbers = myNumbers,
            .copies = 1,
        };
    }

    pub fn winners(self: Card) u32 {
        var answers: u32 = 0;
        for (self.winningNumbers.items) |winner| {
            for (self.myNumbers.items) |mine| {
                if (winner == mine) {
                    answers += 1;
                    break;
                }
            }
        }
        return answers;
    }

    pub fn deinit(self: Card) void {
        self.winningNumbers.deinit();
        self.myNumbers.deinit();
    }
};

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var answer: u32 = 0;
    while (lines.next()) |line| {
        var card = try Card.init(line, allocator);
        defer card.deinit();
        const winners = card.winners();
        if (winners > 0) {
            answer += std.math.pow(u32, 2, winners - 1);
        }
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var cards = std.ArrayList(Card).init(allocator);
    defer cards.deinit();
    while (lines.next()) |line| {
        var card = try Card.init(line, allocator);
        errdefer card.deinit();
        try cards.append(card);
    }

    var answer: u32 = 0;
    for (cards.items, 0..) |card, i| {
        answer += card.copies;
        const winners = card.winners();
        for (i + 1..i + 1 + winners) |j| {
            cards.items[j].copies += card.copies;
        }
        card.deinit();
    }

    return answer;
}
test "Card" {
    const card = try Card.init("Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53", std.testing.allocator);
    defer card.deinit();
    try std.testing.expectEqual(@as(u32, 1), card.number);
    try std.testing.expectEqualSlices(u32, &[_]u32{ 41, 48, 83, 86, 17 }, card.winningNumbers.items);
    try std.testing.expectEqualSlices(u32, &[_]u32{ 83, 86, 6, 31, 17, 9, 48, 53 }, card.myNumbers.items);
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 13), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 30), result);
}

const testInput =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
;
