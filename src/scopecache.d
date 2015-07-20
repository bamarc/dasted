module dscope;

import dsymbols;

import std.algorithm;
import std.range;
import std.typecons;
import std.container.rbtree;

class DScope
{

}

class DScopeCache
{
private:
    alias Element = Tuple!(Offset, DSymbol);
    RedBlackTree!(Element, cmpTuples) mp;
    public static bool cmpTuples(Element a, Element b)
    {
        return a[0] < b[0];
    }

public:
    void add(DSymbol s)
    {
        auto scb = s.scopeBlock();
        if (!scb.isValid())
        {
            return;
        }
        mp.insert(Element(scb.begin.offset, s));
        mp.insert(Element(scb.end.offset, s));
    }

    DSymbol findScope(DSymbol s)
    {
        auto scb = s.scopeBlock();
        auto lb = mp.lowerBound(Element(scb.begin.offset, s));
        if (lb.empty)
        {
            return null;
        }
        auto offset = lb.back()[0];
        auto symb = lb.back()[1];
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
