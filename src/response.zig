const std = @import("std");
const types = @import("types.zig");

/// Response struct representing an HTTP response.
/// Currently buffers the entire body in memory.
pub const Response = struct {
    status: types.Status,
    version: types.Version,
    headers: std.StringHashMap([]const u8),
    body: std.ArrayListUnmanaged(u8),
    allocator: std.mem.Allocator,

    /// Initialize a new Response object
    pub fn init(
        allocator: std.mem.Allocator,
        status: types.Status,
        version: types.Version,
    ) Response {
        return .{
            .status = status,
            .version = version,
            .headers = std.StringHashMap([]const u8).init(allocator),
            .body = .{},
            .allocator = allocator,
        };
    }

    /// Free all memory associated with the response
    pub fn deinit(self: *Response) void {
        var it = self.headers.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.headers.deinit();
        self.body.deinit(self.allocator);
    }

    /// Check if the status code is 2xx
    pub fn isSuccess(self: Response) bool {
        const code = @intFromEnum(self.status);
        return code >= 200 and code < 300;
    }

    /// Get the response body as a string slice
    pub fn text(self: Response) []const u8 {
        return self.body.items;
    }

    /// Parse the response body as JSON into type T.
    /// The returned Parsed(T) owns the allocated memory (via an arena) and must be deinitialized.
    /// NOTE: Unless `options.allocate` is set to `.alloc_always`, strings in the result may
    /// reference the Response body, so the Response must outlive the parsed data.
    pub fn json(self: Response, comptime T: type, options: std.json.ParseOptions) !std.json.Parsed(T) {
        return std.json.parseFromSlice(T, self.allocator, self.body.items, options);
    }

    /// Get a header value by name
    pub fn getHeader(self: Response, name: []const u8) ?[]const u8 {
        return self.headers.get(name);
    }

    /// Add a header (internal use mainly)
    /// Takes ownership of name and value
    pub fn addHeader(self: *Response, name: []u8, value: []u8) !void {
        try self.headers.put(name, value);
    }
};
