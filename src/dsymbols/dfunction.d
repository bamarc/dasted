module dsymbols.dfunction;

import dsymbols.common;

import std.array;
import std.algorithm;

DSymbol[] fromNode(const FunctionDeclaration decl, SymbolState state)
{
    return [new FunctionSymbol(decl)];
}

class FunctionSymbol : DASTSymbol!(SymbolType.FUNC, FunctionDeclaration)
{
    private ScopeBlock _block;

    this(const NodeType decl)
    {
        super(decl);

        info.name = decl.name.text.idup;
        info.position.offset = cast(Offset)decl.name.index;
        if (decl.functionBody is null || decl.functionBody.blockStatement is null)
        {
            return;
        }
        auto bdy = decl.functionBody.blockStatement;
        _block = ScopeBlock(cast(Offset)bdy.startLocation, cast(Offset)bdy.endLocation);
    }

    override ScopeBlock scopeBlock() const
    {
        return _block;
    }
}
