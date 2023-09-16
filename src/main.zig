const std = @import("std");

pub const c = @cImport({
    @cInclude("libpq-fe.h");
});

/// Wraps `PQsendQueryParams`
/// Param formats, values, and lengths are generated using reflection
fn sendQuery(connection: *c.PGconn, query: [*c]const u8, replacements: anytype) ?*c.PGresult {
    // TODO: Build a Zig type -> PostgreSQL OID lookup for param types
    const paramTypes = null;

    // Send all values in binary format
    const paramFormats = [_]c_int{1} ** replacements.len;

    // TODO: Handle more input types
    var paramValues: [replacements.len][*]const u8 = undefined;
    var paramLengths: [replacements.len]c_int = undefined;
    inline for (0..replacements.len) |idx| {
        const value = replacements[idx];
        const elemType = @TypeOf(value);
        const elemInfo = @typeInfo(elemType);

        paramValues[idx] = switch (elemInfo) {
            .Pointer => @ptrCast(value),
            else => @ptrCast(&value), // TODO: Pass primitives by reference?
        };

        paramLengths[idx] = switch (elemInfo) {
            .Pointer => |info| @sizeOf(@typeInfo(info.child).Array.child) * @typeInfo(info.child).Array.len,
            else => @sizeOf(elemType),
        };
    }

    return c.PQexecParams(connection, query, replacements.len, paramTypes, &paramValues, &paramLengths, &paramFormats, 1);
}

pub fn main() !void {
    // TODO: Something useful
}

test "sendQuery" {
    // TODO: Handle failed connection errors
    const connection: *c.PGconn = c.PQconnectdb("postgresql://postgres:mysecretpassword@localhost:5432/postgres").?;

    const setupQuery =
        \\ DROP TABLE IF EXISTS byte_table;
        \\ CREATE TABLE byte_table (id SERIAL, bytes BYTEA, str VARCHAR);
        \\ INSERT INTO byte_table (bytes, str) VALUES ('\xdeadbeef', 'abc');
    ;

    _ = c.PQexec(connection, setupQuery);

    // TODO: Exercise more native and postgres types
    const id = 1; 
    const bytes = "\xDE\xAD\xBE\xEF";
    const str = "abc";

    const query =
        \\ SELECT id, bytes, str
        \\ FROM byte_table
        \\ WHERE id=$1
        \\ AND bytes=$2
        \\ AND str=$3
    ;

    const res = sendQuery(connection, query, .{ std.mem.nativeToBig(i32, id), bytes, str }); // TODO: Convert numeric types in query wrapper
    const result_status = c.PQresultStatus(res);
    try std.testing.expectEqual(result_status, c.PGRES_TUPLES_OK);
    try std.testing.expectEqual(c.PQntuples(res), 1);

    const idLen = 4;
    const idPtr = c.PQgetvalue(res, 0, 0).?;
    try std.testing.expectEqual(c.PQgetlength(res, 0, 0), idLen);
    try std.testing.expectEqual(std.mem.readIntBig(i32, idPtr[0..idLen]), id);

    const bytesLen = 4;
    const bytesPtr = c.PQgetvalue(res, 0, 1).?;
    try std.testing.expectEqual(c.PQgetlength(res, 0, 1), bytesLen);
    try std.testing.expectEqual(bytesPtr[0..bytesLen].*, bytes.*);

    const strLen = 3;
    const strPtr = c.PQgetvalue(res, 0, 2).?;
    try std.testing.expectEqual(c.PQgetlength(res, 0, 2), strLen);
    try std.testing.expectEqual(strPtr[0..strLen].*, str.*);
}
