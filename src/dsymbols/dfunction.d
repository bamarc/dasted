module dsymbols.dfunction;

import dsymbols.common;
import dsymbols.dsymbolbase;

import std.array;
import std.algorithm;

class FunctionSymbol : TypedSymbol!(SymbolType.FUNC)
{
    this(string name, Offset pos, ScopeBlock block)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
    }
}
