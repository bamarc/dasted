module dsymbols.dinterface;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dclass;

import std.algorithm;
import std.array;

class InterfaceSymbol : ClassSymbol
{
    this(string name, Offset pos, ScopeBlock block,
        DType[] baseInterfaces)
    {
        super(name, pos, block, baseInterfaces);
        _info.symbolType = SymbolType.INTERFACE;
    }
}
