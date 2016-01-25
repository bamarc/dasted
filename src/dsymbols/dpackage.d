module dsymbols.dpackage;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dimport;

class PackageSymbol : TypedSymbol!(SymbolType.PACKAGE)
{
    this(string name)
    {
        _info.name = name;
    }

    void addImport(ImportSymbol s)
    {
        _imports ~= s;
        add(s);
    }

    inout(ImportSymbol)[] getImports() inout
    {
        return _imports;
    }

    void addPackage(PackageSymbol s)
    {
        _packages ~= s;
    }

    inout(PackageSymbol)[] getPackages() inout
    {
        return _packages;
    }

    ImportSymbol[] _imports;
    PackageSymbol[] _packages;
}
