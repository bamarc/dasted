module dsymbols.dclass;

import dsymbols.dsymbolbase;
import dsymbols.common;

import std.algorithm;
import std.array;

class ClassSymbol : TypedSymbol!(SymbolType.CLASS)
{
    this(string name, Offset pos, ScopeBlock block)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
    }
}
