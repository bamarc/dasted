module dsymbols.denum;

import dsymbols.common;

class EnumSymbol : DASTSymbol!(SymbolType.ENUM, EnumDeclaration)
{
    this(const EnumDeclaration decl)
    {
        super(decl);
    }


    override DSymbol[] dotAccess()
    {
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        return [];
    }

    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        return;
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }
}
