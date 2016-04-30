module moduleparser;

import dparse.ast;
import dparse.lexer;
import dparse.parser;
import dparse.rollback_allocator;
import std.experimental.allocator;
import std.experimental.allocator.building_blocks.allocator_list;
import std.experimental.allocator.building_blocks.region;
import std.experimental.allocator.building_blocks.null_allocator;
import std.experimental.allocator.mallocator;
import std.typecons;

alias ModuleAllocator = CAllocatorImpl!(AllocatorList!(
    n => Region!Mallocator(128 * 1024), Mallocator));

struct ModuleAST
{
private:
    Module _mod;
    LexerConfig _config;
    const(Token)[] _tokens;
    RollbackAllocator* _allocator;
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

// TODO: move revision into ASTCache

struct ModuleParser
{
private:
    uint rev;
    string src;
    ModuleAST _ast;
public:
    enum uint NO_REVISION = 0;

    this(string src, uint rev = NO_REVISION)
    {
        this.rev = rev;
        this.src = src;
        _ast._scache = new StringCache(StringCache.defaultBucketCount);
        _ast._config.fileName = "";
        _ast._allocator = new RollbackAllocator;
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
