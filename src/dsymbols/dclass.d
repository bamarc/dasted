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
    private ScopeBlock _block;
    this(const ClassDeclaration decl)
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
