module dsymbols.common;

public import dparse.lexer;
public import dparse.ast;

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

interface ISymbol
{
    SymbolType symbolType() const;

    string name() const;
    inout(DType) type() inout;
    Offset position() const;
    string fileName() const;

    ScopeBlock scopeBlock() const;
    final bool hasScope() const
    {
        return scopeBlock().isValid();
    }

    @property inout(ISymbol) parent() inout;
    @property void parent(ISymbol p);
    @property Visibility visibility() const;
    @property void visibility(Visibility v);

    void add(ISymbol s);
    void inject(ISymbol s);

    ISymbol[] dotAccess();
    ISymbol[] findInScope(string name, bool exactMatch);
    ISymbol[] scopeAccess();

    bool applyTemplateArguments(const DType[] tokens);
    bool applyArguments(const DType[] tokens);

    string asString(uint tabs) const;

    ISymbol[] children();
    ISymbol[] injected();
}

struct DType
{
    SimpleDType[] chain;
    bool builtin = false;
    bool evaluate = false;
    string typeString;

    string asString() const
    {
        return join(map!(a => a.asString())(chain), ".");
    }

    this(string name, bool builtin = false)
    {
        chain = [SimpleDType(name, builtin)];
    }

    import std.range;
    this(R)(R r) if (isInputRange!R)
    {
        chain = array(map!(a => SimpleDType(a))(r));
    }
}

struct SimpleDType
{
    string name;
    bool builtin = false;
    DType[] templateArguments;

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


string debugString(const(ISymbol) s)
{
    import std.conv;
    return s.name() ~ " <" ~ to!string(s.symbolType()) ~ ">";
}


