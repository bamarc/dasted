module dsymbols.dsymbolbase;

import dsymbols.common;

import logger;

import std.algorithm;
import std.array;

struct SymbolInfo
{
    SymbolType symbolType;
    string name;
    string fullname;
    DType type;
    ISymbol[] parameters;
    ISymbol[] templateParameters;
    Offset[] usage;
    Offset position;
    ScopeBlock scopeBlock;
    Visibility visibility;

    this(const Token tok)
    {
        name = tok.text.idup;
        position = cast(Offset)tok.index;
    }
}

mixin template NodeVisitor(T, alias k, bool STOP)
{
    override void visit(const T n)
    {
        alias getType = NodeToSymbol!(T);
        auto tmp = new getType(n);
        k(tmp);
        static if (!STOP)
        {
            k.visit(n);
        }
    }
}

class DSymbol : ISymbol
{
    protected SymbolInfo _info;

    this()
    {
        _info.symbolType = SymbolType.NO_TYPE;
    }

    override SymbolType symbolType() const
    {
        return _info.symbolType;
    }

    override SymbolSubType symbolSubType() const
    {
        return SymbolSubType.NO_SUBTYPE;
    }

    override string name() const
    {
        return _info.name;
    }

    override inout(DType) type() inout
    {
        return _info.type;
    }

    override Offset position() const
    {
        return _info.position;
    }

    override string fileName() const
    {
        return _parent is null ? "<no-filename>" : _parent.fileName();
    }

    override ParameterList parameters() const
    {
        return ParameterList.init;
    }

    override ScopeBlock scopeBlock() const
    {
        return _info.scopeBlock;
    }

    override void addToParent(ISymbol parent)
    {
        parent.add(this);
    }

    override void setParentSymbol(ISymbol p)
    {
        _parent = p;
    }

    @property inout(ISymbol) getParent() inout
    {
        return _parent;
    }

    @property override Visibility visibility() const
    {
        return _info.visibility;
    }

    @property override void visibility(Visibility v)
    {
        _info.visibility = v;
    }

    override void add(ISymbol c)
    {
        _children ~= c;
    }

    override void inject(ISymbol a)
    {
        _injected ~= a;
    }

    override string asString(uint tabs) const
    {
        string res;
        foreach (const(ISymbol) c; children()) res ~= "\n" ~ c.asString(tabs + 1);
        return res;
    }

    override ISymbol[] dotAccess()
    {
        return children();
    }

    ISymbol[] currentScopeInnerSymbols()
    {
        return children();
    }

    ISymbol[] currentScopeOuterSymbols()
    {
        return injected().map!(a => a.dotAccess()).join;
    }

    override ISymbol[] scopeAccess()
    {
        auto res = currentScopeOuterSymbols() ~ currentScopeInnerSymbols();
        if (parent() !is null)
        {
            res ~= parent().scopeAccess();
        }
        return res;
    }

    ISymbol[] findInnerSymbolsInScope(string name)
    {
        return currentScopeInnerSymbols().filter!(a => a.name() == name).array;
    }

    ISymbol[] findOuterSymbolsInScope(string name)
    {
        return currentScopeOuterSymbols().filter!(a => a.name() == name).array;
    }

    override ISymbol[] findSymbol(string name)
    {
        auto res = findInnerSymbolsInScope(name);
        if (!res.empty())
        {
            return res;
        }
        res = findOuterSymbolsInScope(name);
        if (res.empty() && parent() !is null)
        {
            return parent().findSymbol(name);
        }
        return res;
    }

    override bool applyTemplateArguments(const DType[] tokens)
    {
        return _info.templateParameters.length == tokens.length;
    }

    override bool applyArguments(const DType[] tokens)
    {
        return _info.parameters.length == tokens.length;
    }

    override inout(ISymbol)[] children() inout
    {
        return _children;
    }

    override inout(ISymbol)[] injected() inout
    {
        return _injected;
    }


    protected ISymbol _parent;
    protected ISymbol[] _children;
    protected ISymbol[] _injected;
}

class TypedSymbol(SymbolType TYPE) : DSymbol
{
    this()
    {
        _info.symbolType = TYPE;
    }
}
