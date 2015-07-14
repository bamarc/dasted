module dsymbols.common;

public import std.d.lexer;
public import std.d.ast;

public import string_interning;

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
}

alias Offset = uint;

struct ScopeBlock
{
    Position begin;
    Position end;
    bool isValid()
    {
        return begin.isValid() && end.isValid();
    }

    this(Offset b, Offset e)
    {
        begin.offset = b;
        end.offset = e;
    }
}

struct Position
{
    Offset _offset = Offset.max;
    Offset _line = Offset.max;
    Offset _column = Offset.max;

    @property auto offset() const {
        return _offset;
    }

    @property void offset(Offset v) {
        _offset = v;
    }

    @property auto column() const {
        return _column;
    }

    @property auto line() const {
        return _line;
    }

    bool isValid() const
    {
        return offset != Offset.max;
    }
}

bool isIn(DSymbol sym, DSymbol scp)
{
    auto scb = scp.scopeBlock();
    auto pos = sym.position().offset;
    return scb.isValid() && scb.begin.offset < pos && scb.end.offset > pos;
}

class DSymbol
{
    protected SymbolType _symbolType = SymbolType.NO_TYPE;
    this(SymbolType t = SymbolType.NO_TYPE)
    {
        _symbolType = t;
    }

    abstract DSymbol[] dotAccess();
    abstract DSymbol[] scopeAccess();
    abstract DSymbol[] templateInstantiation(const Token[] tokens);
    abstract DSymbol[] applyArguments(const Token[] tokens);
    abstract void addSymbol(DSymbol symbol);
    abstract void injectSymbol(DSymbol symbol);
    abstract string name() const;
    abstract string type() const;
    SymbolType symbolType() const
    {
        return _symbolType;
    }
    abstract Position position() const;

    bool hasScope() const
    {
        return scopeBlock().isValid();
    }

    ScopeBlock scopeBlock() const
    {
        return ScopeBlock();
    }

    DSymbol _parent;

    @property inout(DSymbol) parent() inout
    {
        return _parent;
    }
}

struct SymbolInfo
{
    SymbolType symbolType;
    string name;
    string fullname;
    DSymbol type;
    DSymbol[] parameters;
    DSymbol[] templateParameters;
    ubyte[] usage;
    Position position;
}

class DSymbolWithInfo : DSymbol
{
    protected SymbolInfo info;

    this(SymbolType t = SymbolType.NO_TYPE)
    {
        super(t);
    }


    override string name() const
    {
        return info.name;
    }

    override string type() const
    {
        return info.type is null ? string.init : info.type.name();
    }

    override Position position() const
    {
        return info.position;
    }
}

template NodeToSymbol(NODE)
{
    alias NodeToSymbol = int;
}

template NodeToSymbol(NODE : ClassDeclaration)
{
    import dsymbols.dclass;
    alias NodeToSymbol = ClassSymbol;
}

template NodeToSymbol(NODE : FunctionDeclaration)
{
    alias NodeToSymbol = FunctionSymbol;
}

mixin template NodeVisitor(T, alias k, bool STOP)
{
    override void visit(const T n)
    {
        alias getType = NodeToSymbol!(T);
        auto tmp = new getType(n);
        k ~= tmp;
        static if (!STOP)
        {
            n.accept(this);
        }
    }
}

class DASTSymbol(SymbolType TYPE, NODE) : DSymbolWithInfo
{
    alias NodeType = NODE;
    protected const NodeType _node;

    this(const NODE n)
    {
        _node = null;
        super(TYPE);
    }

    protected DSymbol[] _children;
    protected DSymbol[] _adopted;

}
