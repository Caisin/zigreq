const std = @import("std");

/// HTTP Methods re-exported from std.http
pub const Method = std.http.Method;

/// HTTP Version re-exported from std.http
pub const Version = std.http.Version;

/// HTTP Status re-exported from std.http
pub const Status = std.http.Status;

/// Common errors for the HTTP client
pub const Error = error{
    InvalidUrl,
    UnsupportedScheme,
    ConnectionFailed,
    Timeout,
    TooManyRedirects,
    StreamError,
    TlsError,
    OutOfMemory,
    SystemResources,
    NetworkUnreachable,
    HeaderTooLarge,
    BodyTooLarge,
    Unknown,
};

/// Represents a generic HTTP Header
pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

/// Represents the body of a request
pub const BodyType = enum {
    empty,
    bytes,
    owned_bytes,
};

pub const Body = union(BodyType) {
    empty: void,
    bytes: []const u8,
    owned_bytes: []u8,

    pub fn slice(self: Body) []const u8 {
        return switch (self) {
            .empty => &[_]u8{},
            .bytes => |b| b,
            .owned_bytes => |b| b,
        };
    }

    pub fn deinit(self: Body, allocator: std.mem.Allocator) void {
        switch (self) {
            .owned_bytes => |b| allocator.free(b),
            else => {},
        }
    }
};
