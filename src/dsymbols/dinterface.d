module dsymbols.dinterface;

import dsymbols.common;

import std.algorithm;
import std.array;

DSymbol[] fromNode(const InterfaceDeclaration decl)
{
    return [new InterfaceSymbol(decl)];
}

class InterfaceSymbol : DASTSymbol!(SymbolType.INTERFACE, InterfaceDeclaration)
{
    this(const InterfaceDeclaration decl)
    {
        super(decl);
    }
}
