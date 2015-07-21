module dsymbols.dunion;

import dsymbols.common;

import std.algorithm;
import std.array;

DSymbol[] fromNode(const UnionDeclaration decl, SymbolState state)
{
    return [new UnionSymbol(decl)];
}

class UnionSymbol : DASTSymbol!(SymbolType.UNION, UnionDeclaration)
{
    this(const UnionDeclaration decl)
    {
        super(decl);
    }
}
