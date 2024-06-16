const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub const MockBank = struct {
    tickHeight: u32,

    pub fn init() MockBank {
        return MockBank{ .tickHeight = 0 };
    }

    pub fn recordTick(self: *MockBank, _: [Sha256.digest_length]u8) void {
        self.tickHeight += 1;
        // do something with tick hash
    }
};
