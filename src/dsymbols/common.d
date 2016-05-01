module dsymbols.common;

public import dparse.lexer;
public import dparse.ast;

import logger;

import std.algorithm;
import std.array;
import std.typecons;

enum SymbolType
{
    NO_TYPE = 0,
    CLASS,
    INTERFACE,
    STRUCT,
    UNION,
    FUNC,
    TEMPLATE,
    MODULE,
    PACKAGE,
    ENUM,
    ENUM_VAR,
    VAR,
    BLOCK,
    ALIAS,
}

enum SymbolSubType
{
    NO_SUBTYPE = 0,
    IN,
    OUT,
    UNITTEST,
    SCOPE,
}

enum Visibility
{
    NONE,
    PUBLIC = 1 << 0,
    PRIVATE = 1 << 1,
    PROTECTED = 1 << 2,
    PACKAGE = 1 << 3,
    INTERNAL = 1 << 4,
}

alias Offset = uint;
enum BadOffset = uint.max;

struct ScopeBlock
{
    Offset begin;
    Offset end;

    bool isValid()
    {
        return begin != BadOffset && end != BadOffset && begin <= end;
    }

    this(Offset b, Offset e)
    {
        begin = b;
        end = e;
    }

    this(ulong b, ulong e)
    {
        begin = cast(Offset)b;
        end = cast(Offset)e;
    }
}

struct Position
{
    Offset _offset = Offset.max;
    string _fileName;

    this(string fileName, Offset offset)
    {
        _offset = offset;
        _fileName = fileName;
    }

    @property auto offset() const
    {
        return _offset;
    }

    @property void offset(Offset v)
    {
        _offset = v;
    }

    @property auto column() const
    {
        return 0;
    }

    @property auto line() const
    {
        return 0;
    }

    bool isValid() const
    {
        return offset != Offset.max;
    }
}

bool isInside(ISymbol sym, ISymbol scp)
{
    auto scb = scp.scopeBlock();
    auto pos = sym.position();
    return scb.isValid() && scb.begin < pos && scb.end > pos;
}

struct Parameter
{
    string name;
    DType type;
}

alias ISymbolList = ISymbol[];
alias ParameterList = const(Parameter)[];

interface ISymbol
{
    SymbolType symbolType() const;
    SymbolSubType symbolSubType() const;

    string name() const;
    inout(DType) type() inout;
    Offset position() const;
    string fileName() const;
    ParameterList parameters() const;
    ParameterList templateParameters() const;

    ScopeBlock scopeBlock() const;
    final bool hasScope() const
    {
        return scopeBlock().isValid();
    }

    @property final inout(ISymbol) parent() inout
    {
        return getParent();
    }
    @property final void parent(ISymbol p)
    {
        setParentSymbol(p);
        addToParent(p);
    }
    void setParentSymbol(ISymbol p);
    void addToParent(ISymbol p);
    inout(ISymbol) getParent() inout;
    @property Visibility visibility() const;
    @property void visibility(Visibility v);

    void add(ISymbol s);
    void inject(ISymbol s);

    ISymbol[] dotAccess();
    ISymbol[] findSymbol(string name);
    ISymbol[] scopeAccess();

    bool applyTemplateArguments(const DType[] tokens);
    bool applyArguments(const DType[] tokens);

    string asString(uint tabs) const;

    inout(ISymbol)[] children() inout;
    inout(ISymbol)[] injected() inout;
}

interface TypeEvaluator
{
    ISymbol[] evaluate();
}

struct DType
{
    SimpleDType[] chain;
    bool builtin = false;
    string typeString;
    TypeEvaluator evaluate;

    ISymbol[] find(ISymbol s)
    {
        return findType(s, this);
    }

    string asString() const
    {
        return join(map!(a => a.asString())(chain), ".");
    }

    this(string name, bool builtin = false)
    {
        chain = [SimpleDType(name, builtin)];
        this.builtin = builtin;
    }

    this(SimpleDType[] types)
    {
        chain = types;
    }

    this(TypeEvaluator ev)
    {
        evaluate = ev;
    }
}

struct SimpleDType
{
    string name;
    bool builtin = false;
    DType[] templateArguments;

    this(string typeName, bool builtin = false)
    {
        name = typeName;
        this.builtin = builtin;
    }

    bool isTemplated() const
    {
        return !templateArguments.empty();
    }

    string asString() const
    {
        string res = name;
        if (isTemplated())
        {
            res ~= "!(";
            res ~= join(map!(a => a.asString())(templateArguments), ",");
            res ~= ")";
        }
        return res;
    }

}

ISymbol[] findSymbol(R)(ISymbol symbol, R tokenChain)
{
    import std.range;
    debug trace("Finding symbol for ", tokenChain.join("."));
    auto declarations = symbol.findSymbol(tokenChain.front());
    foreach (dotType; tokenChain.dropOne())
    {
        debug trace("declarations = ", map!(a => a.name())(declarations));
        if (declarations.empty())
        {
            break;
        }
        declarations = filter!(a => a.name() == dotType)(
            declarations.front().dotAccess()).array();
    }
    debug trace("Declaration = ", declarations.empty() ? "NO" : debugString(declarations.front()),
        " found for ", tokenChain.join("."));
    return declarations;
}

ISymbol[] findType(ISymbol parent, DType type)
{
    import std.range;
    if (type.evaluate !is null)
    {
        debug trace("Type evaluation may not be implemented for ", debugString(type));
        return type.evaluate.evaluate();
    }

    if (type.builtin || type.chain.empty())
    {
        return null;
    }

    return findSymbol(parent, type.chain.map!(a => a.name));
}

ISymbol[] evaluateType(ISymbol symbol)
{
    debug trace("Evaluate type: ", debugString(symbol));
    if (symbol is null)
    {
        return null;
    }
    return findType(symbol.parent, symbol.type());
}

string debugString(const(ISymbol) s)
{
    import std.conv;
    return s.name() ~ " <" ~ to!string(s.symbolType()) ~ ">  ("
                    ~ debugString(s.type()) ~ ") "
                    ~ s.fileName() ~ ":" ~ to!string(s.position);
}

string debugString(const(DType) t)
{
    return t.asString();
}

struct SafeNull(T)
{
    private T payload;
    this(T p)
    {
        payload = p;
    }

    @property inout(T) get() inout
    {
        return payload;
    }

    @property auto opDispatch(string s)()
    {
            alias memType = SafeNull!(typeof(mixin("this.payload." ~ s)));
            return this.payload is null ? memType.init : memType(mixin("this.payload." ~ s));
    }
}

auto safeNull(T)(T a)
{
    return SafeNull!(T)(a);
}


