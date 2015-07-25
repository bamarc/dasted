module completionfilter;

import cache;
import dsymbols.common;
import logger;

import std.typecons;


class SortedFilter
{
    import std.container.rbtree;
    alias Second = Rebindable!(const(DSymbol));
    alias Element = Tuple!(string, Rebindable!(const(DSymbol)));
    alias RBTree = RedBlackTree!(Element, (a, b) => a[0] < b[0]);
    private RBTree mp;
    enum NullSecond = Second();

    this()
    {
        mp = new RBTree;
    }

    void add(const(DSymbol) sym)
    {
        debug(wlog) log(sym.name());
        auto second = rebindable(sym);
        mp.insert(Element(sym.name(), second));
    }

    auto getPartial(string part)
    {
        import std.array, std.algorithm;
        const(DSymbol)[] result = getExact(part);
        debug(wlog) log(result.length);
        auto upper = mp.upperBound(Element(part, NullSecond));
        while (!upper.empty() && upper.front()[0].startsWith(part))
        {
            debug(wlog) log(upper.front()[0]);
            result ~= upper.front()[1];
            upper.popFront();
        }
        return result;
    }

    auto getExact(string id)
    {
        import std.array, std.algorithm;
        return array(map!(a => a[1].get())(mp.equalRange(Element(id, NullSecond))));
    }
}

class CompletionCache(T) : LazyCache!(DSymbol, T)
{
    this()
    {
        super(0);
    }

    override T initialize(const(DSymbol) k)
    {
        debug(wlog) log(k.name());
        auto ret = new T;
        foreach(const(DSymbol) s; k.dotAccess()) ret.add(s);
        return ret;
    }

    auto fetchPartial(const(DSymbol) s, string part)
    {
        debug(wlog) log(part);
        auto filter = get(s);
        return filter.getPartial(part);
    }

    auto fetchExact(const(DSymbol) s, string id)
    {
        auto filter = get(s);
        return filter.getExact(id);
    }
}
