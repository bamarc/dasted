module dsymbols.dpackage;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dimport;

import logger;

import std.algorithm;

class PackageSymbol : TypedSymbol!(SymbolType.PACKAGE)
{
    this(string name)
    {
        _info.name = name;
    }

    void addImport(ImportSymbol s)
    {
        _imports ~= s;
    }

    inout(ImportSymbol)[] getImports() inout
    {
        return _imports;
    }

    void addPackage(PackageSymbol s)
    {
        _packages ~= s;
    }

    override ISymbol[] dotAccess()
    {
        return cast(ISymbol[])_imports ~ cast(ISymbol[])_packages;
    }

    inout(PackageSymbol)[] getPackages() inout
    {
        return _packages;
    }

    ImportSymbol[] _imports;
    PackageSymbol[] _packages;
}

PackageSymbol[] mergeWithPackageList(PackageSymbol s, PackageSymbol[] list)
{
    debug trace("Merge package ", s.name(), " with ", list.map!(a => a.name()));
    foreach (p; list)
    {
        if (s.name() == p.name())
        {
            foreach (i; s.getImports())
            {
                p.addImport(i);
            }
            foreach (sp; s.getPackages())
            {
                p._packages = mergeWithPackageList(sp, p._packages);
            }
            return list;
        }
    }
    list ~= s;
    return list;
}
