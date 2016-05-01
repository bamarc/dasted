module dsymbols.dstruct;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dthis;

import std.algorithm;
import std.array;


class StructSymbol : TypedSymbol!(SymbolType.STRUCT)
{
    this(string name, Offset pos, ScopeBlock block, ParameterList templateParameters)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;

        _templateParameters = templateParameters;
        _thisSymbol = new ThisSymbol(this);
    }

    override ISymbol[] currentScopeInnerSymbols()
    {
        return super.currentScopeInnerSymbols() ~ _thisSymbol;
    }

    override ParameterList templateParameters() const
    {
        return _templateParameters;
    }

    ThisSymbol _thisSymbol;
    ParameterList _templateParameters;
}
