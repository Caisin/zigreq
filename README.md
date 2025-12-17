# zigreq

A simple, fluent HTTP client library for Zig, built on top of the standard library's `std.http`.

## Features

- **Fluent API**: Easy-to-use builder pattern for constructing requests.
- **Standard Methods**: Supports GET, POST, PUT, DELETE, HEAD, PATCH.
- **HTTPS Support**: Handles TLS connections using the system's certificate bundle.
- **Connection Pooling**: Reuses connections efficiently via `std.http.Client`.
- **Memory Management**: Explicit control over allocation with Zig's allocator pattern.

## Installation

### Using `build.zig.zon` (Zig Package Manager)

1. Add `zigreq` to your `build.zig.zon` dependencies:

   ```zig
   // build.zig.zon
   .{
       .name = "my-project",
       .version = "0.1.0",
       .dependencies = .{
           .zigreq = .{
               .url = "https://github.com/Caisin/zigreq/archive/<COMMIT_HASH>.tar.gz",
               // .hash = "..." // Zig will tell you the correct hash when you run `zig build`
           },
       },
   }
   ```

2. Add the module to your `build.zig`:

   ```zig
   // build.zig
   pub fn build(b: *std.Build) void {
       // ... setup target and optimize ...

       const zigreq = b.dependency("zigreq", .{
           .target = target,
           .optimize = optimize,
       });

       const exe = b.addExecutable(.{
           .name = "my-project",
           .root_source_file = b.path("src/main.zig"),
           .target = target,
           .optimize = optimize,
       });

       exe.root_module.addImport("zigreq", zigreq.module("zigreq"));
       
       // ... install ...
   }
   ```

## Usage

### Basic GET Request

```zig
const std = @import("std");
const zigreq = @import("zigreq");

pub fn main() !void {
    // 1. Setup allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 2. Initialize the Client
    var client = try zigreq.Client.init(allocator, .{});
    defer client.deinit();

    // 3. Create a request builder
    var builder = try client.get("https://httpbin.org/get");
    defer builder.deinit();

    // 4. Add headers (optional)
    _ = try builder.header("User-Agent", "zigreq-example/1.0");
    _ = try builder.header("Accept", "application/json");

    // 5. Send the request
    var response = try builder.send();
    defer response.deinit();

    // 6. Access response data
    std.debug.print("Status: {d}\n", .{@intFromEnum(response.status)});
    
    if (response.getHeader("content-type")) |ct| {
        std.debug.print("Content-Type: {s}\n", .{ct});
    }

    std.debug.print("Body: {s}\n", .{response.text()});
}
```

### POST Request with Body

```zig
const std = @import("std");
const zigreq = @import("zigreq");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zigreq.Client.init(allocator, .{});
    defer client.deinit();

    const url = "https://httpbin.org/post";
    var builder = try client.post(url);
    defer builder.deinit();

    const json_body = "{\"name\": \"Zig\", \"type\": \"Language\"}";
    _ = try builder.body(json_body);
    _ = try builder.header("Content-Type", "application/json");

    var response = try builder.send();
    defer response.deinit();

    std.debug.print("Response: {s}\n", .{response.text()});
}
```

## License

MIT
```
