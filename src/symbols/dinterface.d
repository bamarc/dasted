module dsymbols.dinterface;

import dsymbols.common;

import std.algorithm;
import std.array;

class InterfaceSymbol : DASTSymbol!(SymbolType.INTERFACE, InterfaceDeclaration)
{
    this(const InterfaceDeclaration decl)
    {
        super(decl);
    }

    override DSymbol[] dotAccess()
    {
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }
}
