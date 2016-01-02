module scopecache;

import dsymbols.common;
import logger;

import std.algorithm;
import std.range;
import std.typecons;
import std.container.rbtree;

class ScopeCache
{
private:
    alias Element = Tuple!(Offset, ISymbol);
    RedBlackTree!(Element, cmpTuples) mp;
    public static bool cmpTuples(const Element a, const Element b)
    {
        return a[0] < b[0];
    }

public:
    this()
    {
         mp = new RedBlackTree!(Element, cmpTuples);
    }

    void add(ISymbol s)
    {
        auto scb = s.scopeBlock();
        debug(wlog) log(scb.begin.offset, ' ', scb.end.offset);
        if (!scb.isValid())
        {
            return;
        }
        mp.insert(Element(scb.begin, s));
        mp.insert(Element(scb.end, s));
    }

    ISymbol findScope(Offset pos)
    {
        debug(wlog) log(pos);
        auto lb = mp.lowerBound(Element(pos, null));
        if (lb.empty)
        {
            return null;
        }
        auto offset = lb.back()[0];
        auto symb = lb.back()[1];
        debug(wlog) log("offset = ", offset);
        if (offset == symb.scopeBlock().begin)
        {
            return symb;
        }
        else
        {
            return symb.parent;
        }
    }
}
