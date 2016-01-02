module dsymbols.dimport;

import dsymbols.common;
import dsymbols.dsymbolbase;

import std.array;
import std.algorithm;


class ImportSymbol : TypedSymbol!(SymbolType.MODULE)
{
    this(string[] identifiers, string name, Offset pos)
    {
        _name = identifiers;
        _rename = name;
        _info.name = name;
        _info.position = pos;
    }

    string[] _name;
    string _rename;
}
