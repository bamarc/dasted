module scopecache;

import dsymbols;
import logger;

import std.algorithm;
import std.range;
import std.typecons;
import std.container.rbtree;

class ScopeCache
{
private:
    alias Element = Tuple!(Offset, DSymbol);
    RedBlackTree!(Element, cmpTuples) mp = new RedBlackTree!(Element, cmpTuples);
    public static bool cmpTuples(Element a, Element b)
    {
        return a[0] < b[0];
    }

public:
    void add(DSymbol s)
    {
        auto scb = s.scopeBlock();
        debug(wlog) log(scb.begin.offset, ' ', scb.end.offset);
        if (!scb.isValid())
        {
            return;
        }
        mp.insert(Element(scb.begin.offset, s));
        mp.insert(Element(scb.end.offset, s));
    }

    DSymbol findScope(Offset pos)
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
        if (offset == symb.scopeBlock().begin.offset)
        {
            return symb;
        }
        else
        {
            return symb.parent;
        }
    }
}
