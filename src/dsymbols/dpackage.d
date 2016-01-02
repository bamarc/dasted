module dsymbols.dpackage;

import dsymbols.common;
import dsymbols.dsymbolbase;

class PackageSymbol : TypedSymbol!(SymbolType.PACKAGE)
{
    this(string name)
    {
        _info.name = name;
    }
}
