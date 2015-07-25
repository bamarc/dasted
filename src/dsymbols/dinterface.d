module dsymbols.dinterface;

import dsymbols.common;

import std.algorithm;
import std.array;

DSymbol[] fromNode(const InterfaceDeclaration decl, SymbolState state)
{
    return [new InterfaceSymbol(decl)];
}

class InterfaceSymbol : DASTSymbol!(SymbolType.INTERFACE, InterfaceDeclaration)
{
    private ScopeBlock _block;

    this(const InterfaceDeclaration decl)
    {
        super(decl);
        auto bdy = decl.structBody;
        _block = ScopeBlock(cast(Offset)bdy.startLocation, cast(Offset)bdy.endLocation);
    }

    override ScopeBlock scopeBlock() const
    {
        return _block;
    }
}
