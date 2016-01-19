module dsymbols.dclass;

import dsymbols.dsymbolbase;
import dsymbols.common;

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
    }

    override ISymbol[] dotAccess()
    {
        auto baseClassSymbols =
            _baseClasses.map!(a => findType(this, a)).join().filter!(a => a !is null);
        debug trace("BaseClasses = ", baseClassSymbols.map!(a => a.name()).array.join(","),
            " = ", _baseClasses.map!(a => debugString(a)));
        return baseClassSymbols.map!(a => a.dotAccess()).join.array() ~ super.dotAccess();
    }

    DType[] _baseClasses;
}
