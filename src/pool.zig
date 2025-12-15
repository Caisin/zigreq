const std = @import("std");

/// Configuration for the connection pool
pub const Config = struct {
    /// Maximum number of connections (Hint: std.http.Client manages this internally,
    /// this config is kept for API compatibility with future custom implementations)
    max_connections: usize = 50,
};

/// A thread-safe connection pool wrapper around std.http.Client.
/// Zig's std.http.Client supports connection reuse (keep-alive) by default.
pub const Pool = struct {
    allocator: std.mem.Allocator,
    client: std.http.Client,

    /// Initialize a new connection pool
    pub fn init(allocator: std.mem.Allocator, config: Config) Pool {
        _ = config;
        return .{
            .allocator = allocator,
            .client = std.http.Client{
                .allocator = allocator,
            },
        };
    }

    /// Release all resources associated with the pool
    pub fn deinit(self: *Pool) void {
        self.client.deinit();
    }

    /// Access the underlying std.http.Client
    pub fn getStdClient(self: *Pool) *std.http.Client {
        return &self.client;
    }
};
