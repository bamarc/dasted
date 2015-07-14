module dcache;

import dsymbols;

import dsymbols.dfunction;

import memory.allocators;
import std.allocator;
import std.d.ast;
import std.d.lexer;
import std.d.parser;

import string_interning;

import std.typecons;
import std.range;

import dsymbols.dmodule;

class ModuleCache
{
    void add(string filename)
    {
        auto allocator = scoped!(CAllocatorImpl!(BlockAllocator!(1024 * 16)))();
        auto cache = StringCache(StringCache.defaultBucketCount);
        LexerConfig config;
        config.fileName = "";
        import std.file : readText;
        auto src = cast(ubyte[])readText(filename);
        auto tokenArray = getTokensForParser(src, config, &cache);
//        auto beforeTokens = assumeSorted(tokenArray).lowerBound(pos);
        auto moduleAst = parseModule(tokenArray, internString("stdin"), allocator, function(a,b,c,d,e){});

    }

    private ModuleSymbol[string] ch;

    ModuleSymbol get(string modulename) const
    {
        return null;
    }
}

