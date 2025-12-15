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
        const url = "https://jsonplaceholder.typicode.com/posts/1";
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

        // Print first 200 chars of body if available
        const body = response.text();
        const preview_len = @min(body.len, 200);
        std.debug.print("Body Preview:\n{s}...\n", .{body[0..preview_len]});
    }

    // 3. Perform a POST request
    {
        const url = "https://httpbin.org/post";
        std.debug.print("\n[POST] Requesting {s}...\n", .{url});

        var builder = try client.post(url);
        defer builder.deinit();

        const json_payload =
            \\{
            \\  "name": "Ziggy",
            \\  "role": "Mascot",
            \\  "language": "Zig"
            \\}
        ;

        _ = try builder.header("Content-Type", "application/json");
        _ = try builder.body(json_payload);

        var response = try builder.send();
        defer response.deinit();

        std.debug.print("Status: {d}\n", .{@intFromEnum(response.status)});
        const body = response.text();
        std.debug.print("Response:\n{s}\n", .{body});
    }
}
