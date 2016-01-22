module dsymbols.dvariable;

import dsymbols.common;
import dsymbols.dsymbolbase;

import logger;

import std.algorithm;
import std.array;
import std.range;


class VariableSymbol : TypedSymbol!(SymbolType.VAR)
{
    this(string name, Offset pos, DType type)
    {
        _info.name = name;
        _info.type = type;
        _info.position = pos;
    }

    override ISymbol[] dotAccess()
    {
        debug trace();
        auto declarations = findType(this, type);
        if (declarations.empty())
        {
            return null;
        }
        debug trace("dot access for ", debugString(declarations.front()));
        return declarations.front().dotAccess();
    }
}

class EnumVariableSymbol : TypedSymbol!(SymbolType.ENUM)
{
    this(string name, Offset pos)
    {
       _info.name = name;
       _info.position = pos;
    }
}
