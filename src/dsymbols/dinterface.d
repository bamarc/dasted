module dsymbols.dinterface;

import dsymbols.common;
import dsymbols.dsymbolbase;

import std.algorithm;
import std.array;

class InterfaceSymbol : TypedSymbol!(SymbolType.INTERFACE)
{
    this(string name, ScopeBlock block)
    {
        _info.name = name;
        _info.scopeBlock = block;
    }
}
