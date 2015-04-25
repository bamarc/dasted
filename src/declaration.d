module declaration;

import dsymbols;

import memory.allocators;
import std.allocator;
import std.d.ast;
import std.d.lexer;
import std.d.parser;
import string_interning;

import std.typecons;
import std.algorithm;
import std.range;

DSymbol getDeclaration(string src, ubyte pos)
{
    auto allocator = scoped!(CAllocatorImpl!(BlockAllocator!(1024 * 16)))();
    auto cache = StringCache(StringCache.defaultBucketCount);
    LexerConfig config;
    config.fileName = "";
    auto tokenArray = getTokensForParser(cast(ubyte[])src, config, &cache);
    auto beforeTokens = assumeSorted(tokenArray).lowerBound(pos);
    Module m = parseModule(tokenArray, internString("stdin"), allocator, (a, b, c, d, e) {});

    return null;
}
