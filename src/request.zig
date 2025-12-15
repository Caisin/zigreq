const std = @import("std");
const types = @import("types.zig");
const response = @import("response.zig");
const pool = @import("pool.zig");

/// Builder for constructing HTTP requests
pub const RequestBuilder = struct {
    allocator: std.mem.Allocator,
    pool_ref: *pool.Pool,
    method: types.Method,
    url: []const u8,
    header_map: std.StringHashMap([]const u8),
    request_body: types.Body,

    /// Initialize a new RequestBuilder.
    /// Duplicates the URL to ensure ownership.
    pub fn init(
        allocator: std.mem.Allocator,
        p: *pool.Pool,
        method: types.Method,
        url: []const u8,
    ) !RequestBuilder {
        const url_copy = try allocator.dupe(u8, url);
        return .{
            .allocator = allocator,
            .pool_ref = p,
            .method = method,
            .url = url_copy,
            .header_map = std.StringHashMap([]const u8).init(allocator),
            .request_body = .empty,
        };
    }

    /// Deinitialize the builder and free resources.
    pub fn deinit(self: *RequestBuilder) void {
        self.allocator.free(self.url);
        self.header_map.deinit();
        self.request_body.deinit(self.allocator);
    }

    /// Add a header to the request.
    /// References are stored, but keys/values should be valid until send() is called.
    /// (Ideally, one might want to duplicate these too, but for simplicity/performance
    /// we often rely on literals or scoped strings. To be safe like URL, we could dupe not strictly required by reqwest API but good for builder life).
    /// Let's stick to storing slices, assuming user manages them (like literals).
    /// NOTE: If you pass dynamic strings, ensure they outlive the call to send().
    pub fn header(self: *RequestBuilder, key: []const u8, value: []const u8) !*RequestBuilder {
        try self.header_map.put(key, value);
        return self;
    }

    /// Set the request body.
    /// Copies the content.
    pub fn body(self: *RequestBuilder, content: []const u8) !*RequestBuilder {
        const owned = try self.allocator.dupe(u8, content);
        self.request_body.deinit(self.allocator);
        self.request_body = .{ .owned_bytes = owned };
        return self;
    }

    /// Execute the request and return a Response.
    /// Does NOT deinitialize the RequestBuilder.
    pub fn send(self: *RequestBuilder) !response.Response {
        const client = self.pool_ref.getStdClient();
        const uri = try std.Uri.parse(self.url);

        // Buffer for server headers (8KB standard)
        var server_header_buffer: [8192]u8 = undefined;

        // Collect headers
        var headers_list = std.ArrayListUnmanaged(std.http.Header){};
        defer headers_list.deinit(self.allocator);

        var it = self.header_map.iterator();
        while (it.next()) |entry| {
            try headers_list.append(self.allocator, .{ .name = entry.key_ptr.*, .value = entry.value_ptr.* });
        }

        const payload = self.request_body.slice();

        // Open connection / Create request
        var req = try client.request(self.method, uri, .{
            .extra_headers = headers_list.items,
        });
        defer req.deinit();

        // Send request headers and body
        if (payload.len > 0) {
            req.transfer_encoding = .{ .content_length = payload.len };
            var body_writer = try req.sendBody(&server_header_buffer);
            try body_writer.writer.writeAll(payload);
            try body_writer.end();
        } else {
            req.transfer_encoding = .none;
            try req.sendBodiless();
        }

        var incoming_resp = try req.receiveHead(&server_header_buffer);

        // Build Response object
        var resp = response.Response.init(self.allocator, incoming_resp.head.status, incoming_resp.head.version);
        errdefer resp.deinit();

        // Copy response headers
        var resp_it = incoming_resp.head.iterateHeaders();
        while (resp_it.next()) |h| {
            // We duplicate headers because they point to server_header_buffer which is temporary
            const name = try self.allocator.dupe(u8, h.name);
            const value = try self.allocator.dupe(u8, h.value);
            try resp.addHeader(name, value);
        }

        // Read response body
        var reader_buf: [4096]u8 = undefined;
        const reader = incoming_resp.reader(&reader_buf);
        var buf: [4096]u8 = undefined;

        if (incoming_resp.head.content_length) |len| {
            var remaining = len;
            while (remaining > 0) {
                const to_read_u64 = @min(remaining, @as(u64, buf.len));
                const to_read: usize = @intCast(to_read_u64);
                const n = try reader.readSliceShort(buf[0..to_read]);
                if (n == 0) break;
                try resp.body.appendSlice(self.allocator, buf[0..n]);
                remaining -= n;
            }
        } else {
            while (true) {
                const n = try reader.readSliceShort(&buf);
                if (n == 0) break;
                try resp.body.appendSlice(self.allocator, buf[0..n]);
            }
        }

        return resp;
    }
};
