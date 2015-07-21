module dsymbols.dclass;

import dsymbols.common;

import std.array;
import std.algorithm;

DSymbol[] fromNode(const ClassDeclaration decl, SymbolState state)
{
    return [new ClassSymbol(decl)];
}

class ClassSymbol : DASTSymbol!(SymbolType.CLASS, ClassDeclaration)
{
    this(const ClassDeclaration decl)
    {
        super(decl);

        info.name = decl.name.text.idup;
        info.position.offset = cast(Offset)decl.name.index;
    }
}
