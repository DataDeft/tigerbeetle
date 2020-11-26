const std = @import("std");
const assert = std.debug.assert;
const builtin = std.builtin;
const crypto = std.crypto;
const mem = std.mem;

pub const config = @import("tigerbeetle.conf");

pub const Command = packed enum(u32) {
    // We reserve command "0" to detect any accidental zero byte being interpreted as a command:
    eof = 1,
    ack,
    create_accounts,
    create_transfers,
    commit_transfers,
    lookup_accounts,

    pub fn format(value: Command, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("Command:");
        }
        try writer.writeAll("\"");
        try writer.writeAll(@tagName(value));
        try writer.writeAll("\"");
        return;
    }
};

pub const Account = packed struct {
    id: u128,
    custom: u128,
    flags: AccountFlags,
    unit: u64,
    debit_reserved: u64,
    debit_accepted: u64,
    credit_reserved: u64,
    credit_accepted: u64,
    debit_reserved_limit: u64,
    debit_accepted_limit: u64,
    credit_reserved_limit: u64,
    credit_accepted_limit: u64,
    padding: u64 = 0,
    timestamp: u64 = 0,

    pub inline fn exceeds(balance: u64, amount: u64, limit: u64) bool {
        return limit > 0 and balance + amount > limit;
    }

    pub inline fn exceeds_debit_reserved_limit(self: *const Account, amount: u64) bool {
        return Account.exceeds(self.debit_reserved, amount, self.debit_reserved_limit);
    }

    pub inline fn exceeds_debit_accepted_limit(self: *const Account, amount: u64) bool {
        return Account.exceeds(self.debit_accepted, amount, self.debit_accepted_limit);
    }

    pub inline fn exceeds_credit_reserved_limit(self: *const Account, amount: u64) bool {
        return Account.exceeds(self.credit_reserved, amount, self.credit_reserved_limit);
    }

    pub inline fn exceeds_credit_accepted_limit(self: *const Account, amount: u64) bool {
        return Account.exceeds(self.credit_accepted, amount, self.credit_accepted_limit);
    }

    pub fn format(value: Account, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("Account:");
        }
        try writer.writeAll("{");
        try std.fmt.format(writer, "\"id\":{},", .{value.id});
        try std.fmt.format(writer, "\"custom\":\"{x:0>32}\",", .{value.custom});
        try std.fmt.format(writer, "\"flags\":{" ++ fmt ++ "},", .{value.flags});
        try std.fmt.format(writer, "\"unit\":{},", .{value.unit});
        try std.fmt.format(writer, "\"debit_reserved\":{},", .{value.debit_reserved});
        try std.fmt.format(writer, "\"debit_accepted\":{},", .{value.debit_accepted});
        try std.fmt.format(writer, "\"credit_reserved\":{},", .{value.credit_reserved});
        try std.fmt.format(writer, "\"credit_accepted\":{},", .{value.credit_accepted});
        try std.fmt.format(writer, "\"debit_reserved_limit\":{},", .{value.debit_reserved_limit});
        try std.fmt.format(writer, "\"debit_accepted_limit\":{},", .{value.debit_accepted_limit});
        try std.fmt.format(writer, "\"credit_reserved_limit\":{},", .{value.credit_reserved_limit});
        try std.fmt.format(writer, "\"credit_accepted_limit\":{},", .{value.credit_accepted_limit});
        try std.fmt.format(writer, "\"timestamp\":{}", .{value.timestamp});
        try writer.writeAll("}");
        return;
    }
};

pub const AccountFlags = packed struct {
    padding: u64 = 0,

    pub fn format(value: AccountFlags, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("{}");
        return;
    }
};

pub const Transfer = packed struct {
    id: u128,
    debit_account_id: u128,
    credit_account_id: u128,
    custom_1: u128,
    custom_2: u128,
    custom_3: u128,
    flags: TransferFlags,
    amount: u64,
    timeout: u64,
    timestamp: u64 = 0,

    pub fn format(value: Transfer, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("Transfer:");
        }
        try writer.writeAll("{");
        try std.fmt.format(writer, "\"id\":{},", .{value.id});
        try std.fmt.format(writer, "\"debit_account_id\":{},", .{value.debit_account_id});
        try std.fmt.format(writer, "\"credit_account_id\":{},", .{value.credit_account_id});
        try std.fmt.format(writer, "\"custom_1\":\"{x:0>32}\",", .{value.custom_1});
        try std.fmt.format(writer, "\"custom_2\":\"{x:0>32}\",", .{value.custom_2});
        try std.fmt.format(writer, "\"custom_3\":\"{x:0>32}\",", .{value.custom_3});
        try std.fmt.format(writer, "\"flags\":{" ++ fmt ++ "},", .{value.flags});
        try std.fmt.format(writer, "\"amount\":{},", .{value.amount});
        try std.fmt.format(writer, "\"timeout\":{},", .{value.timeout});
        try std.fmt.format(writer, "\"timestamp\":{}", .{value.timestamp});
        try writer.writeAll("}");
        return;
    }
};

pub const TransferFlags = packed struct {
    accept: bool = false,
    reject: bool = false,
    auto_commit: bool = false,
    condition: bool = false,
    padding: u60 = 0,

    pub fn format(value: TransferFlags, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("TransferFlags:");
        }
        try writer.writeAll("{");
        try std.fmt.format(writer, "\"accept\":{},", .{value.accept});
        try std.fmt.format(writer, "\"reject\":{},", .{value.reject});
        try std.fmt.format(writer, "\"auto_commit\":{},", .{value.auto_commit});
        try std.fmt.format(writer, "\"condition\":{}", .{value.condition});
        try writer.writeAll("}");
        return;
    }
};

pub const Commit = packed struct {
    id: u128,
    custom_1: u128,
    custom_2: u128,
    custom_3: u128,
    flags: CommitFlags,
    timestamp: u64 = 0,

    pub fn format(value: Commit, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("Commit:");
        }
        try writer.writeAll("{");
        try std.fmt.format(writer, "\"id\":{},", .{value.accept});
        try std.fmt.format(writer, "\"custom_1\":{},", .{value.custom_1});
        try std.fmt.format(writer, "\"custom_2\":{},", .{value.custom_2});
        try std.fmt.format(writer, "\"custom_3\":{},", .{value.custom_3});
        try std.fmt.format(writer, "\"flags\":{" ++ fmt ++ "},", .{value.flags});
        try std.fmt.format(writer, "\"timestamp\":{}", .{value.timestamp});
        try writer.writeAll("}");
        return;
    }
};

pub const CommitFlags = packed struct {
    accept: bool = false,
    reject: bool = false,
    preimage: bool = false,
    padding: u61 = 0,

    pub fn format(value: CommitFlags, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("CommitFlags:");
        }
        try writer.writeAll("{");
        try std.fmt.format(writer, "\"accept\":{},", .{value.accept});
        try std.fmt.format(writer, "\"reject\":{},", .{value.reject});
        try std.fmt.format(writer, "\"preimage\":{}", .{value.auto_commit});
        try writer.writeAll("}");
        return;
    }
};

pub const CreateAccountResult = packed enum(u32) {
    ok,
    exists,
    exists_with_different_unit,
    exists_with_different_limits,
    exists_with_different_custom_field,
    exists_with_different_flags,
    reserved_field_custom,
    reserved_field_padding,
    reserved_field_timestamp,
    reserved_flag_padding,
    exceeds_debit_reserved_limit,
    exceeds_debit_accepted_limit,
    exceeds_credit_reserved_limit,
    exceeds_credit_accepted_limit,
    debit_reserved_limit_exceeds_debit_accepted_limit,
    credit_reserved_limit_exceeds_credit_accepted_limit,
};

pub const CreateTransferResult = packed enum(u32) {
    ok,
    exists,
    exists_with_different_debit_account_id,
    exists_with_different_credit_account_id,
    exists_with_different_custom_fields,
    exists_with_different_amount,
    exists_with_different_timeout,
    exists_with_different_flags,
    exists_and_already_committed_and_accepted,
    exists_and_already_committed_and_rejected,
    reserved_field_custom,
    reserved_field_timestamp,
    reserved_flag_padding,
    reserved_flag_accept,
    reserved_flag_reject,
    debit_account_not_found,
    credit_account_not_found,
    accounts_are_the_same,
    accounts_have_different_units,
    amount_is_zero,
    exceeds_debit_reserved_limit,
    exceeds_debit_accepted_limit,
    exceeds_credit_reserved_limit,
    exceeds_credit_accepted_limit,
    auto_commit_must_accept,
    auto_commit_cannot_timeout,
};

pub const CommitTransferResult = packed enum(u32) {
    ok,
    reserved_field_custom,
    reserved_field_timestamp,
    reserved_flag_padding,
    commit_must_accept_or_reject,
    commit_cannot_accept_and_reject,
    transfer_not_found,
    transfer_expired,
    already_auto_committed,
    already_committed,
    already_committed_but_accepted,
    already_committed_but_rejected,
    debit_account_not_found,
    credit_account_not_found,
    debit_amount_was_not_reserved,
    credit_amount_was_not_reserved,
    exceeds_debit_accepted_limit,
    exceeds_credit_accepted_limit,
    condition_requires_preimage,
    preimage_requires_condition,
    preimage_invalid,
};

pub const CreateAccountResults = packed struct {
    index: u32,
    result: CreateAccountResult,
};

pub const CreateTransferResults = packed struct {
    index: u32,
    result: CreateTransferResult,
};

pub const CommitTransferResults = packed struct {
    index: u32,
    result: CommitTransferResult,
};

pub const Magic: u64 = @byteSwap(u64, 0x0a_5ca1ab1e_bee11e); // "A scalable beetle..."

pub const JournalHeader = packed struct {
    // TODO Move these comments to the design doc:
    // This checksum covers this entry's header and becomes the hash chain root.
    // The hash chain root covers all entry checksums in the journal:
    // 1. to protect against journal tampering, and
    // 2. to prove knowledge of history when determining consensus across nodes.
    checksum_meta: u128 = undefined,
    // This checksum covers this entry's data, excluding sector padding:
    // 1. to protect against torn writes and provide crash safety, and
    // 2. to protect against eventual disk corruption.
    checksum_data: u128 = undefined,
    // This binds this entry with the previous journal entry:
    // 1. to protect against misdirected reads/writes by hardware, and
    // 2. to enable "relaxed lock step" quorum across the cluster, enabling
    //    nodes to form a quorum provided their hash chain roots can be
    //    linked together in a directed acyclic graph by a topological sort,
    //    i.e. a node can be one hash chain root behind another to accomodate
    //    crashes without losing quorum.
    prev_checksum_meta: u128,
    // Since entries can be variable length, and since intermediate entries can
    // be corrupted, the entry offset provides a way to repair the journal at
    // the granularity of a single entry:
    offset: u64,
    command: Command,
    // This is the size of this entry's header and data:
    // 1. also covered by checksum_meta and checksum_data respectively, and
    // 2. excluding additional zero byte padding for disk sector alignment,
    //    which is necessary for direct I/O, to reduce copies in the kernel,
    //    and improve write throughput by up to 10%.
    //    e.g. If we write a journal entry for a single transfer of 192 bytes
    //    (64 + 128), we will actually write 4096 bytes, which is the minimum
    //    sector size to work with Advanced Format disks. The size will be 192
    //    bytes, covered by the checksums, and the rest will be zero bytes.
    size: u32,

    pub fn calculate_checksum_meta(self: *const JournalHeader) u128 {
        const meta = @bitCast([@sizeOf(JournalHeader)]u8, self.*);
        const checksum_size = @sizeOf(@TypeOf(self.checksum_meta));
        assert(checksum_size == 16);
        var target: [32]u8 = undefined;
        crypto.hash.Blake3.hash(meta[checksum_size..], target[0..], .{});
        return @bitCast(u128, target[0..checksum_size].*);
    }

    pub fn calculate_checksum_data(self: *const JournalHeader, data: []const u8) u128 {
        assert(@sizeOf(JournalHeader) + data.len == self.size);
        const checksum_size = @sizeOf(@TypeOf(self.checksum_data));
        assert(checksum_size == 16);
        var target: [32]u8 = undefined;
        crypto.hash.Blake3.hash(data[0..], target[0..], .{});
        return @bitCast(u128, target[0..checksum_size].*);
    }

    pub fn set_checksum_meta(self: *JournalHeader) void {
        self.checksum_meta = self.calculate_checksum_meta();
    }

    pub fn set_checksum_data(self: *JournalHeader, data: []const u8) void {
        self.checksum_data = self.calculate_checksum_data(data);
    }

    pub fn valid_checksum_meta(self: *const JournalHeader) bool {
        return self.checksum_meta == self.calculate_checksum_meta();
    }

    pub fn valid_checksum_data(self: *const JournalHeader, data: []const u8) bool {
        return self.checksum_data == self.calculate_checksum_data(data);
    }

    pub fn format(value: JournalHeader, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("JournalHeader:");
        }
        try writer.writeAll("{");
        try std.fmt.format(writer, "\"checksum_meta\":{x:0>32},", .{value.checksum_meta});
        try std.fmt.format(writer, "\"checksum_data\":{x:0>32},", .{value.checksum_data});
        try std.fmt.format(writer, "\"prev_checksum_meta\":{x:0>32},", .{value.prev_checksum_meta});
        try std.fmt.format(writer, "\"offset\":{},", .{value.offset});
        try std.fmt.format(writer, "\"command\":{" ++ fmt ++ "},", .{value.command});
        try std.fmt.format(writer, "\"size\":{}", .{value.size});
        try writer.writeAll("}");
        return;
    }
};

pub const NetworkHeader = packed struct {
    checksum_meta: u128 = undefined,
    checksum_data: u128 = undefined,
    id: u128,
    magic: u64 = Magic,
    command: Command,
    size: u32,

    pub fn calculate_checksum_meta(self: *const NetworkHeader) u128 {
        const meta = @bitCast([@sizeOf(NetworkHeader)]u8, self.*);
        const checksum_size = @sizeOf(@TypeOf(self.checksum_meta));
        assert(checksum_size == 16);
        var target: [32]u8 = undefined;
        crypto.hash.Blake3.hash(meta[checksum_size..], target[0..], .{});
        return @bitCast(u128, target[0..checksum_size].*);
    }

    pub fn calculate_checksum_data(self: *const NetworkHeader, data: []const u8) u128 {
        assert(@sizeOf(NetworkHeader) + data.len == self.size);
        const checksum_size = @sizeOf(@TypeOf(self.checksum_data));
        assert(checksum_size == 16);
        var target: [32]u8 = undefined;
        crypto.hash.Blake3.hash(data[0..], target[0..], .{});
        return @bitCast(u128, target[0..checksum_size].*);
    }

    pub fn set_checksum_meta(self: *NetworkHeader) void {
        self.checksum_meta = self.calculate_checksum_meta();
    }

    pub fn set_checksum_data(self: *NetworkHeader, data: []const u8) void {
        self.checksum_data = self.calculate_checksum_data(data);
    }

    pub fn valid_checksum_meta(self: *const NetworkHeader) bool {
        return self.checksum_meta == self.calculate_checksum_meta();
    }

    pub fn valid_checksum_data(self: *const NetworkHeader, data: []const u8) bool {
        return self.checksum_data == self.calculate_checksum_data(data);
    }

    pub fn valid_size(self: *const NetworkHeader) bool {
        if (self.size < @sizeOf(NetworkHeader)) return false;
        const data_size = self.size - @sizeOf(NetworkHeader);
        const type_size: usize = switch (self.command) {
            .ack => 8,
            .create_accounts => @sizeOf(Account),
            .create_transfers => @sizeOf(Transfer),
            .commit_transfers => @sizeOf(Commit),
            .lookup_accounts => @sizeOf(u128),
            else => unreachable,
        };
        const min_count: usize = switch (self.command) {
            .ack => 0,
            .create_accounts => 1,
            .create_transfers => 1,
            .commit_transfers => 1,
            .lookup_accounts => 1,
            else => unreachable,
        };
        return (@mod(data_size, type_size) == 0 and
            @divExact(data_size, type_size) >= min_count);
    }

    pub fn format(value: NetworkHeader, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "json")) {
            try writer.writeAll("NetworkHeader:");
        }
        try writer.writeAll("{");
        try std.fmt.format(writer, "\"checksum_meta\":\"{x:0>32}\",", .{value.checksum_meta});
        try std.fmt.format(writer, "\"checksum_data\":\"{x:0>32}\",", .{value.checksum_data});
        try std.fmt.format(writer, "\"id\":{},", .{value.id});
        try std.fmt.format(writer, "\"magic\":\"{x:0>16}\",", .{mem.toBytes(value.magic)});
        try std.fmt.format(writer, "\"command\":{" ++ fmt ++ "},", .{value.command});
        try std.fmt.format(writer, "\"size\":{}", .{value.size});
        try writer.writeAll("}");
        return;
    }
};

comptime {
    //    if (builtin.os.tag != .linux) @compileError("linux required for io_uring");

    // We require little-endian architectures everywhere for efficient network deserialization:
    if (builtin.endian != builtin.Endian.Little) @compileError("big-endian systems not supported");
}

const testing = std.testing;

test "magic" {
    testing.expectEqualSlices(u8, ([_]u8{ 0x0a, 0x5c, 0xa1, 0xab, 0x1e, 0xbe, 0xe1, 0x1e })[0..], mem.toBytes(Magic)[0..]);
}

test "data structure sizes" {
    testing.expectEqual(@as(usize, 4), @sizeOf(Command));
    testing.expectEqual(@as(usize, 8), @sizeOf(AccountFlags));
    testing.expectEqual(@as(usize, 128), @sizeOf(Account));
    testing.expectEqual(@as(usize, 8), @sizeOf(TransferFlags));
    testing.expectEqual(@as(usize, 128), @sizeOf(Transfer));
    testing.expectEqual(@as(usize, 8), @sizeOf(CommitFlags));
    testing.expectEqual(@as(usize, 80), @sizeOf(Commit));
    testing.expectEqual(@as(usize, 8), @sizeOf(CreateAccountResults));
    testing.expectEqual(@as(usize, 8), @sizeOf(CreateTransferResults));
    testing.expectEqual(@as(usize, 8), @sizeOf(CommitTransferResults));
    testing.expectEqual(@as(usize, 8), @sizeOf(@TypeOf(Magic)));
    testing.expectEqual(@as(usize, 64), @sizeOf(JournalHeader));
    testing.expectEqual(@as(usize, 64), @sizeOf(NetworkHeader));

    // We swap the network header for a journal header so they must be the same size:
    testing.expectEqual(@sizeOf(JournalHeader), @sizeOf(NetworkHeader));
}