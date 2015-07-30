module dsymbols.dscope;

import dsymbols.common;
import dsymbols.dfunction;

DSymbol[] fromNode(const Unittest decl, SymbolState state)
{
    if (decl.blockStatement is null)
    {
        return null;
    }
    return [new UnnamedScopeSymbol(null, decl.blockStatement.startLocation, decl.blockStatement.endLocation)];
}

class UnnamedScopeSymbol : DASTSymbol!(SymbolType.NO_TYPE, ExpressionNode)
{
    private ScopeBlock _block;

    this(const NodeType decl, ulong start, ulong end)
    {
        super(decl);

        info.name = "";
        _block = ScopeBlock(cast(Offset)start, cast(Offset)end);
    }

    override ScopeBlock scopeBlock() const
    {
        return _block;
    }
}
