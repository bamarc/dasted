module completionfilter;

import cache;
import dsymbols.common;

import std.typecons;


class SortedFilter
{
    import std.container.rbtree;
    alias Second = Rebindable!(const(DSymbol));
    alias Element = Tuple!(string, Rebindable!(const(DSymbol)));
    private RedBlackTree!(Element, (a, b) => a[0] < b[0]) mp;
    enum NullSecond = Second();

    void add(const(DSymbol) sym)
    {
        auto second = rebindable(sym);
        mp.insert(Element(sym.name(), second));
    }

    auto getPartial(string part)
    {
        import std.array, std.algorithm;
        const(DSymbol)[] result = getExact(part);
        auto upper = mp.upperBound(Element(part, NullSecond));
        while (!upper.empty() && upper.front()[0].startsWith(part))
        {
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
        auto ret = new T;
        foreach(const(DSymbol) s; k.dotAccess()) ret.add(s);
        return ret;
    }

    auto fetchPartial(const(DSymbol) s, string part)
    {
        auto filter = get(s);
        return filter.getPartial(part);
    }

    auto fetchExact(const(DSymbol) s, string id)
    {
        auto filter = get(s);
        return filter.getExact(id);
    }
}
