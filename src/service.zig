const std = @import("std");
const Allocator = std.mem.Allocator;

const Recorder = @import("root.zig").Recorder;
const MockBank = @import("root.zig").MockBank;
const Transaction = @import("root.zig").Transaction;
const mockTransactions = @import("root.zig").mockTransactions;

pub const Service = struct {
    thread: ?std.Thread,
    recorder: Recorder,

    pub fn init(allocator: Allocator, bank: MockBank) !Service {
        return Service{
            .thread = null,
            .recorder = try Recorder.init(allocator, bank),
        };
    }

    fn run(self: *Service) !void {
        std.debug.print("start\n", .{});
        while (true) {
            try self.recorder.recordTransactions(&mockTransactions);
            self.recorder.tick();
        }
    }

    pub fn join(self: *Service) !void {
        self.thread = try std.Thread.spawn(.{}, Service.run, .{self});
        self.thread.?.join();
    }

    pub fn deinit(self: *Service) void {
        self.recorder.deinit();
    }
};
