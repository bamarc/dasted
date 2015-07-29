module activemodule;

import dsymbols;
import dmodulecache;
import completionfilter;
import scopecache;
import engine;
import logger;

import std.d.ast;
import std.d.parser;
import std.allocator;
import memory.allocators;

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

    static bool continueSymbol(const(Token) t)
    {
        return (t.type == tok!"identifier"
            || t.type == tok!".");
    }



    void addImportPath(string path)
    {
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
        _completer = new CompleterCache;
        _moduleCache = new ModuleCache;
        _scopeCache = new ScopeCache;
        _cache = StringCache(StringCache.defaultBucketCount);
        _config.fileName = "";
    }

    void setSources(string text)
    {
        _allocator = new CAllocatorImpl!(BlockAllocator!(1024 * 16))();
        _cache = StringCache(StringCache.defaultBucketCount);
        auto src = cast(ubyte[])text;
        _tokenArray = getTokensForParser(src, _config, &_cache);
        _module = parseModule(_tokenArray, internString("stdin"), _allocator, function(a,b,c,d,e){});
        auto visitor = this.new ModuleVisitor(_module);
        visitor.visit(_module);
        _symbol = visitor._moduleSymbol;
    }

    const(DSymbol) getScope(uint pos)
    {
        auto s = _scopeCache.findScope(cast(Offset)pos);
        return s is null ? _symbol : s;
    }

    auto getBeforeTokens(uint pos) const
    {
        return assumeSorted(_tokenArray).lowerBound(pos);
    }

    const(DSymbol)[] complete(uint pos)
    {
        debug(wlog) log(pos);
        auto sc = rebindable(getScope(pos));
        debug(wlog) log("scope = ", sc.asString());
        auto beforeTokens = assumeSorted(_tokenArray).lowerBound(pos);
        const(Token)[] chain;
        while (!beforeTokens.empty() && (beforeTokens.back() == tok!"identifier" || beforeTokens.back() == tok!"."))
        {
            chain ~= beforeTokens.back();
            beforeTokens.popBack();
        }
        return complete(sc, chain, pos);
    }

    private const(DSymbol)[] complete(const(DSymbol) sc, const(Token)[] tokens, uint pos)
    {
        if (tokens.empty())
        {
            return null;
        }
        if (tokens.back() != tok!"identifier")
        {
            return null;
        }
        auto identifier = tokens.back();
        auto txt = identifier.index + identifier.text.length < pos ? identifier.text : identifier.text[0..pos - identifier.index];
        debug(wlog) log("tokens back = ", identifier.text);
        debug(wlog) log("tokens str = ", txt);
        tokens.popBack();
        if (tokens.empty())
        {
            return doComplete(sc, txt);
        }

        if (tokens.back() != tok!".")
        {
            return null;
        }

        auto symb = doFind(sc, txt);
        if (symb.symbolType() == SymbolType.VAR)
        {
            //todo
            //resolve type of var
            return null;
        }

        return complete(symb, tokens, pos);
    }

    const(DSymbol) doFind(const(DSymbol) s, string identifier)
    {
        debug(wlog) log(s.asString(), ": ", identifier);
        Rebindable!(const(DSymbol)) scp = s;
        CompleterCache completer = _completer;
        while (scp !is null)
        {
            debug(wlog) log(scp.name(), ": ", scp.symbolType());
            auto symbols = completer.fetchExact(scp, identifier);
            if (!symbols.empty())
            {
                return symbols.front();
            }
            foreach (const(DSymbol) ad; scp.adopted())
            {
                debug(wlog) log("adopted ", ad.name(), ": ", ad.symbolType());
                if (ad.symbolType() == SymbolType.MODULE)
                {
                    auto modState = _moduleCache.get(ad.name());
                    if (modState !is null)
                    {
                        scp = modState.dmodule();
                        auto result = modState.findExact(identifier);
                        if (!result.empty())
                        {
                            return result.front();
                        }
                    }
                }
            }
            scp = scp.parent;
        }
        return null;
    }

    const(DSymbol)[] doComplete(const(DSymbol) s, string part)
    {
        debug(wlog) log(s.asString(), ": ", part);
        Rebindable!(const(DSymbol)) scp = s;
        CompleterCache completer = _completer;
        while (scp !is null)
        {
            debug(wlog) log(scp.name(), ": ", scp.symbolType());
            auto symbols = completer.fetchPartial(scp, part);
            if (!symbols.empty())
            {
                debug(wlog) log("native", symbols.length);
                return symbols;
            }
            foreach (const(DSymbol) ad; scp.adopted())
            {
                debug(wlog) log("adopted ", ad.name(), ": ", ad.symbolType());
                if (ad.symbolType() == SymbolType.MODULE)
                {
                    auto modState = _moduleCache.get(ad.name());
                    if (modState !is null)
                    {
                        scp = modState.dmodule();
                        auto result = modState.findPartial(part);
                        if (!result.empty())
                        {
                            debug(wlog) log("adopted");
                            return result;
                        }
                    }
                }
            }
            scp = scp.parent;
        }
        return null;
    }
}


unittest
{
    import std.stdio, std.file, std.algorithm;
    auto am = new ActiveModule;
    string src = readText("test/simple.d.txt");
    am.setSources(src);
    am.addImportPath("/usr/local/include/d2/");
    assert(map!(a => a.name())(am.complete(234)).equal(["UsersBase", "UsersDerived", "UsersStruct"]));
    writeln(map!(a => a.name())(am.complete(1036)));
}
