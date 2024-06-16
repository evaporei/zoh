const std = @import("std");
const Allocator = std.mem.Allocator;

const Recorder = @import("root.zig").Recorder;
const MockBank = @import("root.zig").MockBank;
const Transaction = @import("root.zig").Transaction;
const mockTransactions = @import("root.zig").mockTransactions;

pub const Service = struct {
    recorder: Recorder,

    pub fn init(allocator: Allocator, bank: MockBank) !Service {
        return Service{ .recorder = try Recorder.init(allocator, bank) };
    }

    pub fn run(self: *Service) !void {
        std.debug.print("start\n", .{});
        while (true) {
            try self.recorder.recordTransactions(&mockTransactions);
            self.recorder.tick();
        }
    }

    pub fn deinit(self: *Service) void {
        self.recorder.deinit();
    }
};
