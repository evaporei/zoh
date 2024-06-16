pub const MockBank = struct {
    tickHeight: u32,

    pub fn init() MockBank {
        return MockBank{ .tickHeight = 0 };
    }

    pub fn record_tick(self: *MockBank, _: []const u8) void {
        self.tickHeight += 1;
        // do something with tick hash
    }
};
