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
    private ScopeBlock _block;

    this(const StructDeclaration decl)
    {
        super(decl);

        info.name = decl.name.text.idup;
        info.position.offset = cast(Offset)decl.name.index;
        auto bdy = decl.structBody;
        _block = ScopeBlock(cast(Offset)bdy.startLocation, cast(Offset)bdy.endLocation);
    }

    override ScopeBlock scopeBlock() const
    {
        return _block;
    }
}
