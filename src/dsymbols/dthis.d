module dsymbols.dthis;

import dsymbols.common;
import dsymbols.dforward;

class ThisSymbol : ForwardedSymbol
{
    this(ISymbol parent)
    {
        super(parent);
    }

    override string name() const
    {
        return "this";
    }

    override SymbolType symbolType() const
    {
        return SymbolType.NO_TYPE;
    }

    override void addToParent(ISymbol)
    {

    }
}
