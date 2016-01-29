module dsymbols.dimport;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dmodule;
import dsymbols.dforward;

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
        _info.name = importLastName();
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

    bool hasPackages() const
    {
        return _rename.empty() && _name.length > 1;
    }

    string[] packageNames() const
    {
        return hasPackages() ? _name[0 .. $ - 1].dup : [];
    }

    string importLastName() const
    {
        return _rename.empty() ? (_name.empty() ? "" : _name.back()) : _rename;
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

class ImportInjector : ForwardedSymbol
{
    this(ImportSymbol s)
    {
        super(s);
    }

    override ISymbol[] dotAccess()
    {
        return [implSymbol()];
    }

    override void addToParent(ISymbol parent)
    {
        return parent.inject(this);
    }
}
