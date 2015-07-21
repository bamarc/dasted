module dsymbols.denum;

import dsymbols.common;

DSymbol[] fromNode(const EnumDeclaration decl, SymbolState state)
{
    return [new EnumSymbol(decl)];
}

class EnumSymbol : DASTSymbol!(SymbolType.ENUM, EnumDeclaration)
{
    this(const EnumDeclaration decl)
    {
        super(decl);
    }
}
