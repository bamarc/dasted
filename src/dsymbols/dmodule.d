module dsymbols.dmodule;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dfunction;

import std.array;
import std.algorithm;
import std.exception;


class ModuleSymbol : TypedSymbol!(SymbolType.MODULE)
{
    this(string[] name, Offset pos)
    {
        _nameChain = name;
        _info.name = join(name, ".");
        _info.position = pos;
    }

    string[] _nameChain;
}
