module moduleparser;

import dparse.ast;
import dparse.lexer;
import dparse.parser;
import std.experimental.allocator;
import std.typecons;


struct ModuleParser
{
private:
    uint rev;
    string src;
    Module mod;
    LexerConfig config;
    const(Token)[] tokens;
    ParseAllocator allocator;
    StringCache* scache;

public:
    enum uint NO_REVISION = uint.max;

    this(string src, uint rev = NO_REVISION)
    {
        this.rev = rev;
        this.src = src;
        scache = new StringCache(StringCache.defaultBucketCount);
        config.fileName = "";
        allocator = new ParseAllocator;
        tokens = getTokensForParser(cast(ubyte[])src,
            config, scache);
        mod = parseModule(tokens, "stdin", allocator,
            function void(a, b, c, d, e){});
    }

    inout(Module) getModule() inout
    {
        return mod;
    }

    uint revision() const
    {
        return rev;
    }

    string source() const
    {
        return src;
    }
}
