module dsymbols.dunion;

import dsymbols.common;
import dsymbols.dsymbolbase;

import std.algorithm;
import std.array;


class UnionSymbol : TypedSymbol!(SymbolType.UNION)
{
    this(string name, Offset pos, ScopeBlock block)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
    }
}
