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

    abstract inout(DSymbol)[] dotAccess() inout;
    abstract inout(DSymbol)[] scopeAccess() inout;
    abstract inout(DSymbol)[] templateInstantiation(const Token[] tokens) inout;
    abstract inout(DSymbol)[] applyArguments(const Token[] tokens) inout;
    abstract string name() const;

    abstract void rename(string name);

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

    @property void parent(DSymbol p)
    {
        _parent = p;
    }

    debug(print)
    {
        string asString(uint tabs = 0) const
        {
            import std.range, std.conv, std.array;
            return to!string(repeat(' ', tabs)) ~ to!string(symbolType())
                ~ ": " ~ name() ~ " -" ~ type() ~ " +" ~ to!string(position().offset);
        }
    }

    abstract void add(DSymbol c);
    abstract void inject(DSymbol a);
}

struct DType
{
    string[] identifiers;
}

struct SymbolInfo
{
    SymbolType symbolType;
    string name;
    string fullname;
    DType type;
    DSymbol[] parameters;
    DSymbol[] templateParameters;
    Position[] usage;
    Position position;

    this(const Token tok)
    {
        name = tok.text.idup;
        position.offset = cast(Offset)tok.index;
    }
}

string tokToString(IdType t)
{
    import std.d.lexer;
    return str(t);
}

DType toDType(const(Type) type)
{
    if (type is null || type.type2 is null)
    {
        return DType();
    }
    if (type.type2.builtinType != tok!"")
    {
        return DType([tokToString(type.type2.builtinType)]);
    }
    else if (type.type2.symbol !is null)
    {
        auto tmp = type.type2.symbol.identifierOrTemplateChain;
        auto chain = tmp.identifiersOrTemplateInstances;
        static string asString(const IdentifierOrTemplateInstance x)
        {
            if (x.templateInstance is null)
            {
                return x.identifier.text.idup;
            }
            string result = x.templateInstance.identifier.text.idup;
            auto ta = x.templateInstance.templateArguments;
            if (ta is null)
            {
                return result;
            }
            result ~= "!";
            if (ta.templateArgumentList is null)
            {
                result ~= ta.templateSingleArgument.token.text.idup;
            }
            else
            {
                static string typeToString(const(Type) t)
                {
                    return join(toDType(t).identifiers, ".");
                }
                result ~= (join(array(map!(a => a.type is null ? "AssignExpression" : typeToString(a.type))
                    (ta.templateArgumentList.items)), ", "));
            }
            return result;
        }
        return DType(array(map!(a => asString(a))(chain)));
    }
    return DType();
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

    override void rename(string name)
    {
        info.name = name;
    }

    override string type() const
    {
        return join(info.type.identifiers, ".");
    }

    override Position position() const
    {
        return info.position;
    }
}

template NodeToSymbol(NODE)
{
    static assert(false, "Need to specialize");
}

template NodeToSymbol(NODE : VariableDeclaration)
{
    import dsymbols.dvariable;
    alias NodeToSymbol = VariableSymbol;
}

template NodeToSymbol(NODE : ClassDeclaration)
{
    import dsymbols.dclass;
    alias NodeToSymbol = ClassSymbol;
}

template NodeToSymbol(NODE : FunctionDeclaration)
{
    import dsymbols.dfunction;
    alias NodeToSymbol = FunctionSymbol;
}

template NodeToSymbol(NODE : Module)
{
    import dsymbols.dmodule;
    alias NodeToSymbol = ModuleSymbol;
}

template NodeToSymbol(NODE : StructDeclaration)
{
    import dsymbols.dstruct;
    alias NodeToSymbol = StructSymbol;
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

class DASTSymbol(SymbolType TYPE, NODE) : DSymbolWithInfo
{
    alias NodeType = NODE;
    protected const NodeType _node;

    this(const NODE n)
    {
        _node = null;
        super(TYPE);
    }

    final override void add(DSymbol c)
    {
        _children ~= c;
        c.parent = this;
    }

    final override void inject(DSymbol a)
    {
        _adopted ~= a;
    }

    debug(print)
    {
        override string asString(uint tabs = 0) const
        {
            auto res = super.asString(tabs);
            foreach (const(DSymbol) c; _children) res ~= "\n" ~ c.asString(tabs + 1);
            return res;
        }
    }


    override inout(DSymbol)[] dotAccess() inout
    {
        return _children;
    }

    override inout(DSymbol)[] scopeAccess() inout
    {
        return _adopted;
    }

    override inout(DSymbol)[] templateInstantiation(const Token[] tokens) inout
    {
        return [this];
    }

    override inout(DSymbol)[] applyArguments(const Token[] tokens) inout
    {
        return [this];
    }


    protected DSymbol[] _children;
    protected DSymbol[] _adopted;

}
