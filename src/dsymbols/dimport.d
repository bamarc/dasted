module dsymbols.dimport;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dmodule;

import astcache;
import modulecache;

import std.array;
import std.algorithm;


class ImportSymbol : TypedSymbol!(SymbolType.MODULE)
{
    this(string[] identifiers, string name, Offset pos,
         ModuleSymbol s)
    {
        _name = identifiers;
        _rename = name;
        _info.name = name;
        _info.position = pos;
        _moduleCache = s.moduleCache();
    }

    string[] _name;
    string _rename;

    ModuleCache _moduleCache;
}
