module dsymbols.dtemplate;

import dsymbols.common;
import dsymbols.dsymbolbase;

import std.algorithm;
import std.array;


class TemplateSymbol : TypedSymbol!(SymbolType.TEMPLATE)
{
    this(string name, Offset pos, ScopeBlock block)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
    }
}
