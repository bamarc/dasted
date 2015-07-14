module dsymbols.dpackage;

import dsymbols.common;

class PackageSymbol : DASTSymbol!(SymbolType.PACKAGE, ModuleDeclaration)
{
    this(const ModuleDeclaration decl)
    {
        super(null);
        _symbolType = SymbolType.PACKAGE;
    }
}
