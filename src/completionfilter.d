module completionfilter;

import dsymbols.common;
import std.typecons;

class SortedFilter
{
    import std.container.rbtree;
    alias Element = Tuple!(string, DSymbol);
    private RedBlackTree!(Element, (a, b) => a[0] < b[0]) mp;

    void add(DSymbol sym)
    {
        mp.insert(tuple(sym.name(), sym));
    }

    auto get(string part)
    {
        import std.array, std.algorithm;
        const(DSymbol)[] result = array(map!(a => a[1])(mp.equalRange(Element(part, null))));
        auto upper = mp.upperBound(Element(part, null));
        while (!upper.empty() && upper.front()[0].startsWith(part))
        {
            result ~= upper.front()[1];
            upper.popFront();
        }
        return result;
    }
}

class CompletionCache(T)
{
    private T[DSymbol] ch;

    auto fetch(DSymbol s, string part)
    {
        auto p = s in ch;
        auto filter = p is null ? new T : *p;
        if (p is null)
        {
            foreach (DSymbol sym; s.dotAccess()) filter.add(sym);
            ch[s] = filter;
        }
        return filter.get(part);
    }
}
