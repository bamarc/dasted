module engine;

import dsymbols;
import dmodulecache;
import completionfilter;
import logger;

import std.algorithm;
import std.typecons;
import std.traits;
import std.range;
import std.exception;

class SimpleCompletionEngine
{
    Rebindable!(const(DSymbol)) _scope;
    ModuleCache _modules;
    const(Token)[] _tokens;
    uint _pos;

    void setState(const(DSymbol) scp, const(Token)[] tokens, uint pos)
    {
        _scope = scp;
        _tokens = tokens;
        _pos = pos;
    }

    @property const(Token) curr() const
    {
        return _tokens.back();
    }

    bool next()
    {
        _tokens.popBack();
        return !_tokens.empty();
    }

    bool empty() const
    {
        return _tokens.empty();
    }

    bool needComplete() const
    {
        return _pos < curr.index + curr.text.length;
    }

    string tokenText() const
    {
        return needComplete() ? curr.text[0.._pos - curr.index] : curr.text;
    }

    alias Callback = const(DSymbol)[] delegate(const(Object));
    alias CallbackMap = Callback[TypeInfo];
    alias TokenType = typeof(Token.type);
    CallbackMap[TokenType] callbacks;

    auto invoke(TokenType t, const(DSymbol) sym)
    {
        trace("SCE: invoke ", t, " ", sym.name());
        auto pt = t in callbacks;
        if (pt is null)
        {
            log("Unexpected token type");
            return null;
        }
        auto ps = typeid(typeof(sym)) in *pt;
        if (ps is null)
        {
            auto pdef = typeid(DSymbol) in *pt;
            if (pdef is null)
            {
                log("Unhandled symbol type without default action");
                return null;
            }
            return (*pdef)(sym);
        }
        return (*ps)(sym);
    }

    const(DSymbol)[] dotComplete(const(DSymbol) sym)
    {
        return inScopeSymbols(sym);
    }
    const(DSymbol)[] dotComplete(const(ImportSymbol) imp)
    {
        auto state = _modules.get(imp.name());
        if (state is null)
        {
            return null;
        }
        return inScopeSymbols(state.dmodule());
    }
    const(DSymbol)[] dotComplete(const(VariableSymbol) sym)
    {
        auto dtype = sym.type();
        if (dtype.chain.empty())
        {
            return null;
        }
        assert(sym !is null);
        assert(sym.parent !is null);

        auto firstType = dtype.chain.front();
        if (dtype.chain.front().builtin)
        {
            enforce(dtype.chain.length == 1, "Builtin type can not be a part of type chain");
            // todo
            // return standart members like max, init, etc
            return null;
        }
        auto symbols = scopeSymbols(sym.parent);
        foreach (const(SimpleDType) st; dtype.chain)
        {
            auto foundSymbols = find(symbols, st.name);
            if (foundSymbols.length != 1)
            {
                // todo
                // type specializations, various template arguments, etc
                return null;
            }
            symbols = startDotCompletion(foundSymbols);
        }
        return symbols;
    }

    const(DSymbol)[] startDotCompletion(const(DSymbol)[] symbols)
    {
        debug(wlog) trace("SCE: dotCompleteStart");
        return array(joiner(map!(a => dispatchCall!"dotComplete"(a))(symbols)));
    }

    const(DSymbol)[] find(bool exact = true)(const(DSymbol)[] symbols, string txt)
    {
        debug(wlog) trace("SCE: find with ", txt, " (exact = ", exact, ")");
        static if (exact)
        {
            return array(filter!(a => a.name() == txt)(symbols));
        }
        else
        {
            return array(filter!(a => a.name().startsWith(txt))(symbols));
        }
    }

    const(DSymbol)[] find(const(DSymbol)[] symbols, string txt, bool exact)
    {
        return exact ? find!true(symbols, txt) : find!false(symbols, txt);
    }

    const(DSymbol)[] scopeSymbols(const(DSymbol) s)
    {
        typeof(return) res;
        Rebindable!(const(DSymbol)) scp = s;
        while (scp !is null)
        {
            res ~= scp.children();
            foreach (const(DSymbol) adop; scp.adopted())
            {
                trace("SCE: scopeSymbols adopted ", adop.name());
                res ~= dispatchCall!"dotComplete"(adop);
            }
            scp = scp.parent;
        }
        debug(wlog) trace("SCE: scopeSymbols symbols = ", res.length);
        return res;
    }

    const(DSymbol)[] inScopeSymbols(const(DSymbol) s)
    {
        return s.children();
    }

    template FirstArg(F)
    {
        import std.traits;
        alias FirstArg = ParameterTypeTuple!F[0];
    }

    auto dispatchCall(string action, Args...)(const(Object) o, Args args)
    {
        trace("dispatch ", typeid(o));
        foreach (f; __traits(getOverloads, this, action))
        {
            alias ST = FirstArg!(typeof(f));
            alias UST = Unqual!ST;
            if (typeid(o) == typeid(UST))
            {
                trace("dispatched ", ST.stringof);
                return f(cast(ST)(o), args);
            }
        }
        static if (__traits(compiles, mixin("this." ~ action ~ "(cast(const DSymbol)(o))")))
        {
            trace("dispatched const(DSymbol)");
            mixin("return this." ~ action ~ "(cast(const DSymbol)(o));");
        }
        else
        {
            trace("dispatched not");
            return null;
        }
    }

    auto DispatchMap(string action)()
    {
        CallbackMap res;
        foreach (f; __traits(getOverloads, this, action))
        {
            alias ST = FirstArg!(typeof(f));
            res[typeid(FirstArg!(typeof(f)))] = (const(Object) o)
            {
                auto v = cast(const(ST))(o);
                return f(v);
            };
        }
        return res;
    }

    this(ModuleCache modules)
    {
        _modules = modules;
        callbacks[tok!"."] = DispatchMap!("dotComplete")();
    }

    const(DSymbol)[] complete()
    {
        trace("SCE: complete ", array(map!(t => t.text)(_tokens)));
        auto scp = _scope;
        if (curr.type == tok!"." && scp.parent !is null)
        {
            scp = scp.parent;
            next();
        }
        debug(wlog) trace("SCE: scope = ", scp.name());
        auto symbols = scopeSymbols(scp);
        debug(wlog) trace("SCE: tokens loop ", empty(), " ", symbols.empty());
        while (!empty() && !symbols.empty())
        {
            trace("SCE: token type ", tokToString(curr.type));
            switch (curr.type)
            {
            case tok!".": symbols = startDotCompletion(symbols); break;
            case tok!"identifier": symbols = find(symbols, tokenText(), !needComplete()); break;
            default: symbols = null;
            }
            next();
        }
        trace("SCE: result = ", array(map!(a => a.name())(symbols)));
        return symbols;
    }
}


class SortedCachedCompletionEngine
{
    CompleterCache _cache;
    Rebindable!(const(DSymbol)) _scope;
    ModuleCache _modules;

    const(Token)[] _tokens;

    uint _pos;

    @property const(Token) curr() const
    {
        return _tokens.front();
    }

    bool needComplete() const
    {
        return _pos < curr.index + curr.text.length;
    }

    string tokenText() const
    {
        return needComplete() ? curr.text[0.._pos - curr.index] : curr.text;
    }

    alias Callback = const(DSymbol)[] delegate(const(Object));
    alias CallbackMap = Callback[TypeInfo];
    alias TokenType = typeof(Token.type);
    CallbackMap[TokenType] callbacks;

    auto invoke(TokenType t, const(DSymbol) sym)
    {
        auto pt = t in callbacks;
        if (pt is null)
        {
            log("Unexpected token type");
            return null;
        }
        auto ps = typeid(typeof(sym)) in *pt;
        if (ps is null)
        {
            auto pdef = typeid(DSymbol) in *pt;
            if (pdef is null)
            {
                log("Unhandled symbol type without default action");
                return null;
            }
            return (*pdef)(sym);
        }
        return (*ps)(sym);
    }

    const(DSymbol)[] dotComplete(const(ImportSymbol) imp) { return null; }
    const(DSymbol)[] dotComplete(const(ModuleSymbol) mod) { return null; }
    const(DSymbol)[] identifierComplete(const(ModuleSymbol) mod) { return null; }

    this(const(DSymbol) scp, CompleterCache completer)
    {
        _scope = scp;
        if (scp.symbolType() == SymbolType.MODULE)
        {
            auto st = _modules.get(scp.name());
            if (st is null)
            {
                return;
            }
            _cache = st.completer;
            return;
        }
        _cache = completer;
    }

    const(DSymbol)[] find(bool exact)(string name)
    {
        const(DSymbol)[] res;
        Rebindable!(const(DSymbol)) scp =_scope;
        while (scp !is null)
        {
            res ~= _cache.fetch!exact(scp, name);
            foreach (const(DSymbol) s; scp.adopted())
            {
//                auto modState =
//                auto adoptedFinder = scoped!SymbolFinder(s);
//                res ~= adoptedFinder.find!exact(name);
            }
            scp = scp.parent;
        }
        return res;
    }

    const(DSymbol)[] findChild(bool exact)(string name)
    {
        return _cache.fetch!exact(scp, name);
    }

    const(DSymbol)[] find(const(DSymbol) s, const(Token) t, uint pos)
    {
        return null;
    }

    const(DSymbol)[] complete(const(DSymbol) s, const(Token)[] chain, uint pos)
    {
        auto scp = rebindable(s);
        if (chain.empty())
        {
            return null;
        }

        auto curr = &chain.front();

        bool next()
        {
            chain.popFront();
            if (chain.empty())
            {
                return false;
            }
            curr = &chain.front();
            return true;
        }

        string text()
        {
            return pos > curr.index + curr.text.length ? curr.text : curr.text[0.. pos - curr.index];
        }

        if (curr.type == tok!".")
        {
            if (scp.parent !is null)
            {
                scp = scp.parent;
            }
            if (!next) return null;
        }

        auto symbols = find!false(text());

        while (next())
        {
            if (curr.type == tok!".") {}
        }
        return symbols;
    }

    template FirstArg(F)
    {
        import std.traits;
        alias FirstArg = ParameterTypeTuple!F[0];
    }

    auto Dispatch(string action)()
    {
        CallbackMap res;
        foreach (f; __traits(getOverloads, this, action))
        {
            alias ST = FirstArg!(typeof(f));
            res[typeid(FirstArg!(typeof(f)))] = (const(Object) o)
            {
                auto v = cast(ST)(o);
                return f(v);
            };
        }
        return res;
    }

    this()
    {
        callbacks[tok!"."] = Dispatch!("dotComplete")();
        callbacks[tok!"identifier"] = Dispatch!("identifierComplete")();
    }

    const(DSymbol)[] complete(uint pos)
    {
        return null;
    }
}
