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
         ModuleSymbol s, Visibility v)
    {
        _name = identifiers;
        _rename = name;
        _info.name = name;
        _info.position = pos;
        _moduleCache = s.moduleCache();
        _info.visibility = v;
    }


    @property override void visibility(Visibility)
    {
        return;
    }

    override ISymbol[] dotAccess()
    {
        auto m = moduleSymbol();
        return m is null ? null : m.dotAccess()
            ~ filter!(a => a.visibility() == Visibility.PUBLIC)(
            m.injected()).map!(a => a.dotAccess()).join().array();
    }

    override void addToParent(ISymbol parent)
    {
        parent.inject(this);
    }

    ModuleSymbol moduleSymbol()
    {
        return _moduleCache.getModule(_name.join("."));
    }

    string[] _name;
    string _rename;

    ModuleCache _moduleCache;
}
