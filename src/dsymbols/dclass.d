module dsymbols.dclass;

import dsymbols.dsymbolbase;
import dsymbols.common;
import dsymbols.dthis;

import logger;

import std.algorithm;
import std.array;
import std.string;

class ClassSymbol : TypedSymbol!(SymbolType.CLASS)
{
    this(string name, Offset pos, ScopeBlock block,
        DType[] baseClasses)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
        _baseClasses = baseClasses;

        _thisSymbol = new ThisSymbol(this);
    }

    auto baseClassSymbols()
    {
        return _baseClasses.map!(a => findType(parent(), a)).join().filter!(a => a !is null);
    }

    override ISymbol[] dotAccess()
    {
        debug trace("BaseClasses = ", baseClassSymbols().map!(a => a.name()).array.join(","),
            " = ", _baseClasses.map!(a => debugString(a)));
        return baseClassSymbols().map!(a => a.dotAccess()).join ~ super.dotAccess();
    }

    override ISymbol[] currentScopeInnerSymbols()
    {
        return super.currentScopeInnerSymbols() ~ _thisSymbol;
    }

    override ISymbol[] currentScopeOuterSymbols()
    {
        return baseClassSymbols().map!(a => a.dotAccess()).join;
    }

    override ParameterList templateParameters() const
    {
        return _templateParameters;
    }

    DType[] _baseClasses;
    ThisSymbol _thisSymbol;
    ParameterList _templateParameters;
}
