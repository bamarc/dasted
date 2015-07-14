module dsymbols.dvariable;

import dsymbols.common;

class VarSymbol : DASTSymbol!(SymbolType.VAR, VariableDeclaration)
{
    this(const VariableDeclaration decl)
    {
        super(decl);
    }

    override void addSymbol(DSymbol symbol)
    {
        return;
    }

    override void injectSymbol(DSymbol symbol)
    {
        return;
    }

    override DSymbol[] dotAccess()
    {
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        return [];
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }
}

class EnumVarSymbol : DASTSymbol!(SymbolType.ENUM, EnumMember)
{
    this(const EnumMember mem)
    {
       super(mem);
    }


    override void addSymbol(DSymbol symbol)
    {
        return;
    }

    override void injectSymbol(DSymbol symbol)
    {
        return;
    }

    override DSymbol[] dotAccess()
    {
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        return [];
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }
}
