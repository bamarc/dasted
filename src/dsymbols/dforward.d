module dsymbols.dforward;

import dsymbols.common;

class ForwardedSymbol : ISymbol
{
    private ISymbol _impl;

    this(ISymbol impl)
    {
        _impl = impl;
    }

    protected inout(ISymbol) implSymbol() inout
    {
        return _impl;
    }

    override SymbolType symbolType() const
    {
        return _impl.symbolType();
    }

    override string name() const
    {
        return _impl.name();
    }

    override inout(DType) type() inout
    {
        return _impl.type();
    }

    override Offset position() const
    {
        return _impl.position();
    }

    override string fileName() const
    {
        return _impl.fileName();
    }

    override ScopeBlock scopeBlock() const
    {
        return _impl.scopeBlock();
    }

    override void setParentSymbol(ISymbol p)
    {
        _impl.setParentSymbol(p);
    }

    override void addToParent(ISymbol p)
    {
        _impl.addToParent(p);
    }

    @property inout(ISymbol) getParent() inout
    {
        return _impl.parent();
    }

    @property override Visibility visibility() const
    {
        return _impl.visibility();
    }

    @property override void visibility(Visibility v)
    {
        _impl.visibility(v);
    }

    override void add(ISymbol c)
    {
        _impl.add(c);
    }

    override void inject(ISymbol a)
    {
        _impl.inject(a);
    }

    override string asString(uint tabs) const
    {
        return _impl.asString(tabs);
    }

    override ISymbol[] dotAccess()
    {
        return _impl.dotAccess();
    }

    override ISymbol[] scopeAccess()
    {
        return _impl.scopeAccess();
    }

    override ISymbol[] findSymbol(string name)
    {
        return _impl.findSymbol(name);
    }

    override bool applyTemplateArguments(const DType[] tokens)
    {
        return _impl.applyTemplateArguments(tokens);
    }

    override bool applyArguments(const DType[] tokens)
    {
        return _impl.applyArguments(tokens);
    }

    override inout(ISymbol)[] children() inout
    {
        return _impl.children();
    }

    override inout(ISymbol)[] injected() inout
    {
        return _impl.injected();
    }

}
