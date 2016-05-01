module dsymbols.dinterface;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dclass;

import std.algorithm;
import std.array;

class InterfaceSymbol : ClassSymbol
{
    this(string name, Offset pos, ScopeBlock block,
        DType[] baseInterfaces, ParameterList templateParameters)
    {
        super(name, pos, block, baseInterfaces, templateParameters);
        _info.symbolType = SymbolType.INTERFACE;
    }
}
