module dsymbols.denum;

import dsymbols.common;
import dsymbols.dsymbolbase;

class EnumSymbol : TypedSymbol!(SymbolType.ENUM)
{
    this(string name, Offset pos, ScopeBlock block)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;
    }
}
