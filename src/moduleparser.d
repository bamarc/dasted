module moduleparser;

import dparse.ast;
import dparse.lexer;
import dparse.parser;
import std.experimental.allocator;
import std.typecons;

struct ModuleAST
{
private:
    Module _mod;
    LexerConfig _config;
    const(Token)[] _tokens;
    ParseAllocator _allocator;
    StringCache* _scache;
public:
    inout(Module) getModule() inout
    {
        return _mod;
    }

    const(Token)[] tokens() inout
    {
        return _tokens;
    }
}


struct ModuleParser
{
private:
    uint rev;
    string src;
    ModuleAST _ast;
public:
    enum uint NO_REVISION = uint.max;

    this(string src, uint rev = NO_REVISION)
    {
        this.rev = rev;
        this.src = src;
        _ast._scache = new StringCache(StringCache.defaultBucketCount);
        _ast._config.fileName = "";
        _ast._allocator = new ParseAllocator;
        _ast._tokens = getTokensForParser(cast(ubyte[])src,
            _ast._config, _ast._scache);
        _ast._mod = parseModule(ast._tokens, "stdin", _ast._allocator,
            function void(a, b, c, d, e){});
    }

    inout(Module) getModule() inout
    {
        return ast.getModule();
    }

    const(Token)[] tokens() inout
    {
        return ast.tokens();
    }

    inout(ModuleAST) ast() inout
    {
        return _ast;
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
