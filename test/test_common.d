module test_common;

import dsymbols.common;

import std.typecons;
import std.string;

struct SourcePos
{
    string src;
    Offset[] pos;
}

SourcePos getSourcePos(string sources, string cursor = "|")
{
    Offset[] pos;
    ptrdiff_t ind = -1;
    while ((ind = sources.indexOf(cursor, ind + 1)) != -1)
    {
        pos ~= cast(Offset)(ind);
    }

    Offset correction = 0;
    string src = sources;
    foreach (ref p; pos)
    {
        p -= correction;
        correction += cursor.length;
        src = src.replace(cursor, "");
    }
    assert(pos.length > 0);
    return SourcePos(src, pos);
}

unittest
{
    string src1 = "1234|5678|9|0|";
    auto res1 = getSourcePos(src1);
    assert(res1.src == "1234567890");
    assert(res1.pos == [4, 8, 9, 10]);

    string src2 = "1234|+|5678|+|9|+|0|+|";
    auto res2 = getSourcePos(src2, "|+|");
    assert(res2.src == "1234567890");
    assert(res2.pos == [4, 8, 9, 10]);
}
