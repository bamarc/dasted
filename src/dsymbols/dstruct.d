module dsymbols.dstruct;

import dsymbols.common;
import dsymbols.dsymbolbase;

import std.algorithm;
import std.array;


class StructSymbol : TypedSymbol!(SymbolType.STRUCT)
{
    this(string name, Offset pos, ScopeBlock block)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
    }
}
