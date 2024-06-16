const std = @import("std");
const Recorder = @import("root.zig").Recorder;
const MockBank = @import("root.zig").MockBank;

pub const Service = struct {
    recorder: Recorder,

    pub fn init(bank: MockBank) !Service {
        return Service{ .recorder = try Recorder.init(bank) };
    }

    pub fn run(self: *Service) !void {
        std.debug.print("start\n", .{});
        while (true) {
            var mock_trxs = std.ArrayList([]const u8).init(std.heap.page_allocator);
            for (0..20) |i| {
                var buf: [5]u8 = undefined;
                const mock_trx = try std.fmt.bufPrint(&buf, "trx{d}", .{i});
                try mock_trxs.append(mock_trx);
            }
            defer mock_trxs.deinit();
            try self.recorder.recordTransactions(mock_trxs.items);
            try self.recorder.tick();
        }
    }

    pub fn deinit(self: *Service) void {
        self.recorder.deinit();
    }
};
