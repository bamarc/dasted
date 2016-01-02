module dsymbols.dblock;

import dsymbols.common;
import dsymbols.dsymbolbase;


class DBlock : DSymbol
{
    this(ScopeBlock block)
    {
        _info.scopeBlock = block;
    }
}
