const std = @import("std");

const zoh = @import("root.zig");
const MockBank = zoh.MockBank;
const Service = zoh.Service;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bank = MockBank.init();
    var service = try Service.init(allocator, bank);
    defer service.deinit();
    try service.run();
}
