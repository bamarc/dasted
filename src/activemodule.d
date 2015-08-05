module activemodule;

import dsymbols;
import modulecache;
import completionfilter;
import scopecache;
import engine;
import logger;

import std.d.ast;
import std.d.parser;
import std.allocator;

import std.typecons;
import std.array;
import std.algorithm;
import std.range;

alias Engine = SimpleCompletionEngine;

class ActiveModule
{
    debug (print_ast) int ast_depth = 0;
    private CompleterCache _completer;
    private ScopeCache _scopeCache;
    private ModuleCache _moduleCache;
    private Engine _engine;

    static bool continueToken(const(Token) t)
    {
        return (t.type == tok!"identifier"
            || t.type == tok!".");
    }

    void addImportPath(string path)
    {
        trace("Add import path: ", path);
        _moduleCache.addImportPath(path);
    }

    class ModuleVisitor : ASTVisitor
    {
        void defaultAction(T, R)(const T node, SymbolState st, R parent, R symbol)
        {
            symbol.addToParent(parent);
            _scopeCache.add(symbol);
        }

        mixin template VisitNode(T, Flag!"Stop" stop, alias action = defaultAction)
        {
            override void visit(const T node)
            {
                auto sym = fromNode(node, _state);
                if (sym is null)
                {
                    return;
                }
                debug (print_ast) log(repeat(' ', ast_depth++), T.stringof);
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
        mixin VisitNode!(FunctionDeclaration, No.Stop);
        mixin VisitNode!(UnionDeclaration, No.Stop);
        mixin VisitNode!(ImportDeclaration, Yes.Stop);
        mixin VisitNode!(Unittest, No.Stop);

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
    CAllocator _allocator;
    StringCache _cache;
    const(Token)[] _tokenArray;

    this()
    {
        _completer = new CompleterCache;
        _moduleCache = new ModuleCache;
        _scopeCache = new ScopeCache;
        _cache = StringCache(StringCache.defaultBucketCount);
        _engine = new Engine(_moduleCache);
        _config.fileName = "";
    }

    void setSources(string text)
    {
        if (text.empty)
        {
            if (_symbol is null)
            {
                parseSources(text);
            }
            // null message - no update
            return;
        }
        parseSources(text);
    }

    private void parseSources(string text)
    {
        _symbol = null;
        _allocator = new ParseAllocator;
        _cache = StringCache(StringCache.defaultBucketCount);
        auto src = cast(ubyte[])text;
        _tokenArray = getTokensForParser(src, _config, &_cache);
        _module = parseModule(_tokenArray, "stdin", _allocator, function(a,b,c,d,e){});
        auto visitor = this.new ModuleVisitor(_module);
        visitor.visit(_module);
        _symbol = visitor._moduleSymbol;
    }

    const(DSymbol) getScope(uint pos)
    {
        auto s = _scopeCache.findScope(cast(Offset)pos);
        return s is null ? _symbol : s;
    }

    auto getBeforeTokens(Offset pos) const
    {
        return assumeSorted(_tokenArray).lowerBound(pos);
    }

    Tuple!(const(DSymbol), const(Token)[]) getState(uint pos)
    {
        auto sc = rebindable(getScope(pos));
        assert(sc !is null);
        trace("Scope = ", sc.name(), " [", to!string(sc.symbolType()), "] found on pos = ", pos);
        auto beforeTokens = getBeforeTokens(pos);
        const(Token)[] chain;
        while (!beforeTokens.empty() && continueToken(beforeTokens.back()))
        {
            chain ~= beforeTokens.back();
            beforeTokens.popBack();
        }
        return tuple(sc.get, chain);
    }

    void updateState(uint pos)
    {
        auto state = getState(pos);
        _engine.setState(state[0], state[1], pos);
    }

    const(DSymbol)[] complete(Offset pos)
    {
        trace("Complete: pos = ", pos);
        updateState(pos);
        auto res = _engine.complete();
        trace("Complete: found ", res.length, " symbols (", join(map!(a => a.name())(res[0..min(3, $)]), ", "), ")");
        return res;
    }

    const(DSymbol)[] find(Offset pos)
    {
        trace("Find: pos = ", pos);
        updateState(pos);
        auto res = _engine.findDeclaration();
        trace("Find: found ", res.length, " symbols (", join(map!(a => a.name())(res[0..min(3, $)]), ", "), ")");
        return res;
    }

}


unittest
{
    import std.stdio, std.file, std.algorithm;
    auto am = new ActiveModule;
    string src = readText("test/simple.d.txt");
    am.setSources(src);
    am.addImportPath("/usr/local/include/d2/");
    assert(sort(map!(a => a.name())(am.complete(234)).array()).equal(["UsersBase", "UsersDerived", "UsersStruct"]));
    auto writeCompletions = am.complete(1036);
    assert(sort(map!(a => a.name())(writeCompletions).array()).equal(["write", "writef", "writefln", "writeln"]));
    auto writeDeclarations = am.find(1036);
    assert(sort(map!(a => a.name())(writeDeclarations).array()).equal(["write"]));
    assert(writeCompletions.front().fileName() == "/usr/local/include/d2/std/stdio.d");
    auto subClassCompletions = am.complete(1109);
    assert(sort(map!(a => a.name())(subClassCompletions).array()).equal(["SubClass"]));
    assert(subClassCompletions.front().fileName().empty());
    assert(sort(map!(a => a.name())(am.complete(1171)).array()).equal(["SubClass", "get"]));
    assert(sort(map!(a => a.name())(am.complete(1172)).array()).equal(["get"]));

}
