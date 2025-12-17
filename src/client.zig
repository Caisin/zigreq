const std = @import("std");
const request_mod = @import("request.zig");
const types = @import("types.zig");

/// Configuration options for the Client
pub const ClientOptions = struct {
    // Empty for now - placeholder for future options
};

/// The main HTTP Client struct.
/// Provides a lightweight wrapper around std.http.Client.
pub const Client = struct {
    allocator: std.mem.Allocator,
    client: std.http.Client,

    /// Create a new Client instance.
    pub fn init(allocator: std.mem.Allocator, options: ClientOptions) Client {
        _ = options;
        return .{
            .allocator = allocator,
            .client = std.http.Client{
                .allocator = allocator,
            },
        };
    }

    /// Deinitialize the Client.
    pub fn deinit(self: *Client) void {
        self.client.deinit();
    }

    /// Start building a request with a specific method and URL.
    pub fn request(self: *Client, method: types.Method, url: []const u8) !request_mod.RequestBuilder {
        return request_mod.RequestBuilder.init(self.allocator, &self.client, method, url);
    }

    /// Start building a GET request.
    pub fn get(self: *Client, url: []const u8) !request_mod.RequestBuilder {
        return self.request(.GET, url);
    }

    /// Start building a POST request.
    pub fn post(self: *Client, url: []const u8) !request_mod.RequestBuilder {
        return self.request(.POST, url);
    }

    /// Start building a PUT request.
    pub fn put(self: *Client, url: []const u8) !request_mod.RequestBuilder {
        return self.request(.PUT, url);
    }

    /// Start building a DELETE request.
    pub fn delete(self: *Client, url: []const u8) !request_mod.RequestBuilder {
        return self.request(.DELETE, url);
    }

    /// Start building a HEAD request.
    pub fn head(self: *Client, url: []const u8) !request_mod.RequestBuilder {
        return self.request(.HEAD, url);
    }

    /// Start building a PATCH request.
    pub fn patch(self: *Client, url: []const u8) !request_mod.RequestBuilder {
        return self.request(.PATCH, url);
    }
};
