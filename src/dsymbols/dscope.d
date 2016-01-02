module dsymbols.dscope;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dfunction;

class UnnamedScopeSymbol : TypedSymbol!(SymbolType.NO_TYPE)
{
    this(string name, Offset pos, ScopeBlock block)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
    }
}
