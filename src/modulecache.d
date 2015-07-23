module dmodulecache;

import cache;
import dsymbols;
import completionfilter;
import scopecache;

import memory.allocators;
import std.allocator;
import std.d.ast;
import std.d.lexer;
import std.d.parser;
import string_interning;

import std.typecons;
import std.range;

debug (print_ast)
{
    import std.stdio;
    uint ast_depth = 0;
}

alias Completer = CompletionCache!SortedFilter;

class ModuleState
{
    import std.file, std.datetime;

    private string _filename;
    private SysTime _modTime;
    private ModuleSymbol _module;
    private Completer _completer;

    private void getModule()
    {
        import std.path;
        auto allocator = scoped!(CAllocatorImpl!(BlockAllocator!(1024 * 16)))();
        auto cache = StringCache(StringCache.defaultBucketCount);
        LexerConfig config;
        config.fileName = "";
        import std.file : readText;
        auto src = cast(ubyte[])readText(_filename);
        auto tokenArray = getTokensForParser(src, config, &cache);
//        auto beforeTokens = assumeSorted(tokenArray).lowerBound(pos);
        auto moduleAst = parseModule(tokenArray, internString("stdin"), allocator, function(a,b,c,d,e){});
        auto visitor = scoped!ModuleVisitor(moduleAst);
        visitor.visit(moduleAst);
        if (visitor._moduleSymbol.name().empty())
        {
            visitor._moduleSymbol.rename(baseName(stripExtension(_filename)));
        }
        _module = visitor._moduleSymbol;
    }

    static void defaultAction(T, R)(const T node, SymbolState st, R parent, R symbol)
    {
        symbol.addToParent(parent);
    }

    static void child(T, R)(const T node, R parent, R symbol)
    {
        parent.add(symbol);
    }

    static void adopt(T, R)(const T node, R parent, R symbol)
    {
        parent.inject(symbol);
    }

    static class ModuleVisitor : ASTVisitor
    {

        mixin template VisitNode(T, Flag!"Stop" stop, alias action = defaultAction)
        {
            override void visit(const T node)
            {
                auto sym = fromNode(node, _state);
                debug (print_ast) writeln(repeat(' ', ast_depth++), T.stringof);
                foreach (DSymbol s; sym) action(node, _state, _symbol, s);
                static if(!stop)
                {
                    auto tmp = _symbol;
                    assert(sym.length == 1);
                    _symbol = sym.front();
                    node.accept(this);
                    _symbol = tmp;
                }
                debug (print_ast) --ast_depth;
            }
        }

        this(const Module mod)
        {
            _moduleSymbol = new ModuleSymbol(mod);
            _symbol = _moduleSymbol;
        }

        private DSymbol _symbol = null;
        private ModuleSymbol _moduleSymbol = null;
        mixin VisitNode!(ClassDeclaration, No.Stop);
        mixin VisitNode!(StructDeclaration, No.Stop);
        mixin VisitNode!(VariableDeclaration, Yes.Stop);
        mixin VisitNode!(FunctionDeclaration, Yes.Stop);
        mixin VisitNode!(UnionDeclaration, No.Stop);
        mixin VisitNode!(ImportDeclaration, Yes.Stop);

        override void visit(const Declaration decl)
        {
            _state.attributes = decl.attributes;
            decl.accept(this);
            _state.attributes = null;
        }

        private alias visit = ASTVisitor.visit;
        private SymbolState _state;
    }


    this(string filename)
    {
        _filename = filename;
        _modTime = timeLastModified(filename);
        getModule();
        _completer = new Completer;
    }

    @property inout(Completer) completer() inout
    {
        return _completer;
    }

    @property inout(ModuleSymbol) dmodule() inout
    {
        return _module;
    }

    const(DSymbol)[] findExact(string id)
    {
        return findExact(_module, id);
    }

    const(DSymbol)[] findExact(const(DSymbol) s, string id)
    {
        return _completer.fetchExact(s, id);
    }

    const(DSymbol)[] findPartial(string part)
    {
        return findPartial(_module, part);
    }

    const(DSymbol)[] findPartial(const(DSymbol) s, string part)
    {
        return _completer.fetchPartial(_module, part);
    }
}

class ModuleCache : LazyCache!(string, ModuleState)
{
    this()
    {
        super(0);
    }

    override ModuleState initialize(const(string) s)
    {
        return new ModuleState(s);
    }
}

unittest
{
    import std.stdio;
    auto ch = new ModuleCache;
    auto st = ch.get("test/simple.d.txt");
    writeln(st.dmodule.asString());
}

class ActiveModule
{
    private Completer _completer;
    private ScopeCache _scopeCache;

    static class ModuleVisitor : ASTVisitor
    {
        static void defaultAction(T, R)(const T node, SymbolState st, R parent, R symbol)
        {
            symbol.addToParent(parent);
        }

        mixin template VisitNode(T, Flag!"Stop" stop, alias action = defaultAction)
        {
            override void visit(const T node)
            {
                auto sym = fromNode(node, _state);
                debug (print_ast) writeln(repeat(' ', ast_depth++), T.stringof);
                foreach (DSymbol s; sym) action(node, _state, _symbol, s);
                static if(!stop)
                {
                    auto tmp = _symbol;
                    assert(sym.length == 1);
                    _symbol = sym.front();
                    node.accept(this);
                    _symbol = tmp;
                }
                debug (print_ast) --ast_depth;
            }
        }

        this(const Module mod)
        {
            _moduleSymbol = new ModuleSymbol(mod);
            _symbol = _moduleSymbol;
        }

        private DSymbol _symbol = null;
        private ModuleSymbol _moduleSymbol = null;
        mixin VisitNode!(ClassDeclaration, No.Stop);
        mixin VisitNode!(StructDeclaration, No.Stop);
        mixin VisitNode!(VariableDeclaration, Yes.Stop);
        mixin VisitNode!(FunctionDeclaration, Yes.Stop);
        mixin VisitNode!(UnionDeclaration, No.Stop);
        mixin VisitNode!(ImportDeclaration, Yes.Stop);

        override void visit(const Declaration decl)
        {
            _state.attributes = decl.attributes;
            decl.accept(this);
            _state.attributes = null;
        }

        private alias visit = ASTVisitor.visit;
        private SymbolState _state;
    }

    Module _module;
    ModuleSymbol _symbol;

    LexerConfig _config;
    CAllocatorImpl!(BlockAllocator!(1024 * 16)) _allocator;
    StringCache _cache;
    const(Token)[] _tokenArray;

    this()
    {
        _cache = StringCache(StringCache.defaultBucketCount);
        _config.fileName = "";
    }

    void setSources(string text)
    {
        _allocator = new CAllocatorImpl!(BlockAllocator!(1024 * 16))();
        _cache = StringCache(StringCache.defaultBucketCount);
        auto src = cast(ubyte[])text;
        _tokenArray = getTokensForParser(src, _config, &_cache);
//        auto beforeTokens = assumeSorted(tokenArray).lowerBound(pos);
        _module = parseModule(_tokenArray, internString("stdin"), _allocator, function(a,b,c,d,e){});
        auto visitor = scoped!ModuleVisitor(_module);
        visitor.visit(_module);
        _symbol = visitor._moduleSymbol;
    }

    const(DSymbol) getScope(uint pos)
    {
        auto s = _scopeCache.findScope(cast(Offset)pos);
        return s is null ? _symbol : s;
    }

    const(DSymbol)[] complete(uint pos)
    {
        auto sc = getScope(pos);
        auto beforeTokens = assumeSorted(_tokenArray).lowerBound(pos);
        const(Token)[] chain;
        while (beforeTokens.back() == tok!"identifier" || beforeTokens.back() == tok!".")
        {
            chain ~= beforeTokens.back();
            beforeTokens.popBack();
        }
        return complete(sc, chain);
    }

    private const(DSymbol)[] complete(const(DSymbol) sc, const(Token)[] tokens)
    {
        if (tokens.back() != tok!"identifier")
        {
            return null;
        }
        auto identifier = tokens.back();
        tokens.popBack();
        if (tokens.empty())
        {
            return doComplete(sc, identifier);
        }

        if (tokens.back() != tok!".")
        {
            return null;
        }
        auto symb = doFind(sc, identifier);
        if (symb.symbolType() == SymbolType.VAR)
        {
            //todo
            return null;
        }

        return complete(symb, tokens);
    }

    const(DSymbol) doFind(const(DSymbol) s, const(Token) identifier)
    {
        //todo
        return null;
    }

    const(DSymbol)[] doComplete(const(DSymbol) s, const(Token) part)
    {
        //todo
        return null;
    }

//    DSymbol[] complete();
}

