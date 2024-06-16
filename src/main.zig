const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

const Poh = struct {
    currHash: []u8,
    hashesPerTick: u32,
    numHashes: u32,
    remainingHashes: u32,

    fn init(initialHash: []const u8, hashesPerTick: u32) !Poh {
        const copiedHash = try std.heap.page_allocator.dupe(u8, initialHash);
        return Poh{
            .currHash = copiedHash,
            .hashesPerTick = hashesPerTick,
            .numHashes = 0,
            .remainingHashes = hashesPerTick,
        };
    }

    fn nextHash(self: *Poh) !void {
        var hasher = Sha256.init(.{});
        hasher.update(self.currHash);
        std.heap.page_allocator.free(self.currHash);
        self.currHash = try std.heap.page_allocator.dupe(u8, &hasher.finalResult());
        self.numHashes += 1;
        self.remainingHashes -= 1;
    }

    fn tick(self: *Poh) !void {
        while (self.remainingHashes > 0) {
            std.debug.print("new hash\n", .{});
            try self.nextHash();
        }
        std.debug.print("reset\n", .{});
        try self.reset();
    }

    fn reset(self: *Poh) !void {
        self.numHashes = 0;
        self.remainingHashes = self.hashesPerTick;
    }

    fn deinit(self: *Poh) void {
        std.heap.page_allocator.free(self.currHash);
    }
};

const Recorder = struct {
    poh: Poh,

    fn init() !Recorder {
        return Recorder{ .poh = try Poh.init("initial hash", 5) };
    }

    fn tick(self: *Recorder) !void {
        std.debug.print("tick\n", .{});
        try self.poh.tick();
        std.time.sleep(2 * 1e9);
    }

    fn deinit(self: *Recorder) void {
        self.poh.deinit();
    }
};

const Service = struct {
    recorder: Recorder,

    fn init() !Service {
        return Service{ .recorder = try Recorder.init() };
    }

    fn run(self: *Service) !void {
        std.debug.print("start\n", .{});
        while (true) {
            try self.recorder.tick();
        }
    }

    fn deinit(self: *Service) void {
        self.recorder.deinit();
    }
};

pub fn main() !void {
    var service = try Service.init();
    defer service.deinit();
    try service.run();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
