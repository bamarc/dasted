module dsymbols.denum;

import dsymbols.common;
import dsymbols.dsymbolbase;

class EnumSymbol : TypedSymbol!(SymbolType.ENUM)
{
    this(string name)
    {
        _info.name = name;
    }
}
