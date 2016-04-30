module dsymbols.dblock;

import dsymbols.common;
import dsymbols.dsymbolbase;

class DBlock : DSymbol
{
    this(ScopeBlock block, SymbolSubType subType = SymbolSubType.SCOPE)
    {
        _info.symbolType = SymbolType.BLOCK;
        _info.scopeBlock = block;
        _subType = subType;
    }

    override SymbolSubType symbolSubType() const
    {
        return _subType;
    }

    private SymbolSubType _subType;
}
