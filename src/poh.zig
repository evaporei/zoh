const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub const Poh = struct {
    currHash: []u8,
    hashesPerTick: u32,
    numHashes: u32,
    remainingHashes: u32,

    pub fn init(initialHash: []const u8, hashesPerTick: u32) !Poh {
        const copiedHash = try std.heap.page_allocator.dupe(u8, initialHash);
        return Poh{
            .currHash = copiedHash,
            .hashesPerTick = hashesPerTick,
            .numHashes = 0,
            .remainingHashes = hashesPerTick,
        };
    }

    fn nextHash(self: *Poh, mixin: []const u8) !void {
        var hasher = Sha256.init(.{});
        hasher.update(self.currHash);
        hasher.update(mixin);
        std.heap.page_allocator.free(self.currHash);
        self.currHash = try std.heap.page_allocator.dupe(u8, &hasher.finalResult());
        self.numHashes += 1;
        self.remainingHashes -= 1;
    }

    pub fn tick(self: *Poh, mixin: []const u8) ![]const u8 {
        while (self.remainingHashes > 0) {
            std.debug.print("new hash\n", .{});
            try self.nextHash(mixin);
        }
        std.debug.print("reset\n", .{});
        const final = try std.heap.page_allocator.dupe(u8, self.currHash);
        try self.reset();
        return final;
    }

    fn reset(self: *Poh) !void {
        self.numHashes = 0;
        self.remainingHashes = self.hashesPerTick;
    }

    pub fn deinit(self: *Poh) void {
        std.heap.page_allocator.free(self.currHash);
    }
};
