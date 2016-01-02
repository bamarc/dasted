module dsymbols.dvariable;

import dsymbols.common;
import dsymbols.dsymbolbase;

import std.array;
import std.algorithm;


class VariableSymbol : TypedSymbol!(SymbolType.VAR)
{
    this(string name, Offset pos, DType type)
    {
        _info.name = name;
        _info.type = type;
        _info.position = pos;
    }
}

class EnumVariableSymbol : TypedSymbol!(SymbolType.ENUM)
{
    this(string name)
    {
       _info.name = name;
    }
}
