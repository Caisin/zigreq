const std = @import("std");
const zigreq = @import("zigreq");

pub fn main() !void {
    // Setup allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Initialize the Client
    // The client holds a connection pool and configuration.
    var client = zigreq.Client.init(allocator, .{});
    // Ensure we free resources at the end
    defer client.deinit();

    std.debug.print("zigreq Client initialized.\n", .{});

    // 2. Perform a GET request
    // We create a scope to manage resources (req, resp) cleanly
    {
        // const url = "https://httpbin.org/get";
        // const url = "https://jsonplaceholder.typicode.com/posts/1";
        // for () |value| {}
        const uris = [_][]const u8{
            // "https://httpbin.org/get",
            "https://jsonplaceholder.typicode.com/posts/1",
            "https://videomgr.qinjiu8.com/basic-api/param/sys_setting",
        };
        for (uris) |url| {
            std.debug.print("\n[GET] Requesting {s}...\n", .{url});

            // Start building a GET request
            // The RequestBuilder needs to be deinitialized to free the copied URL string
            var builder = try client.get(url);
            defer builder.deinit();

            // Add custom headers
            _ = try builder.header("User-Agent", "zigreq-example/1.0");
            _ = try builder.header("Accept", "application/json");

            // Execute the request
            var response = try builder.send();
            // Response owns the body and headers memory, so it must be deinitialized
            defer response.deinit();

            std.debug.print("Status: {d}\n", .{@intFromEnum(response.status)});
            if (response.getHeader("content-type")) |ct| {
                std.debug.print("Content-Type: {s}\n", .{ct});
            }
            std.debug.print("Body Length: {d} bytes\n", .{response.text().len});

            var headers = response.headers.iterator();
            while (headers.next()) |h| {
                std.debug.print("{s}: {s}\n", .{ h.key_ptr.*, h.value_ptr.* });
            }

            // Print first 200 chars of body if available
            const body = response.text();
            const preview_len = @min(body.len, 2000);
            std.debug.print("Body Preview:\n{s}...\n", .{body[0..preview_len]});
        }
    }
}
