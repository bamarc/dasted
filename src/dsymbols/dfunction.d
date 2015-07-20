module dsymbols.dfunction;

import dsymbols.common;

import std.array;
import std.algorithm;

DSymbol[] fromNode(const FunctionDeclaration decl)
{
    return [new FunctionSymbol(decl)];
}

class FunctionSymbol : DASTSymbol!(SymbolType.FUNC, FunctionDeclaration)
{
    this(const NodeType decl)
    {
        super(decl);

        info.name = decl.name.text.idup;
        info.position.offset = cast(Offset)decl.name.index;
    }
}
