module dsymbols.dstruct;

import dsymbols.common;

import std.algorithm;
import std.array;

DSymbol[] fromNode(const StructDeclaration decl, SymbolState state)
{
    return [new StructSymbol(decl)];
}

class StructSymbol : DASTSymbol!(SymbolType.STRUCT, StructDeclaration)
{
    this(const StructDeclaration decl)
    {
        super(decl);

        info.name = decl.name.text.idup;
        info.position.offset = cast(Offset)decl.name.index;
    }
}
