module engine;

import dsymbols;
import dmodulecache;
import completionfilter;
import logger;

import std.algorithm;
import std.typecons;
import std.range;

class CompletionEngine
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
    const(DSymbol)[] dotComplete(const(ModuleSymbol) mod) {return null;}

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
    }
}
