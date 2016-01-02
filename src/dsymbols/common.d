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

string tokToString(IdType t)
{
    import dparse.lexer;
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
        return DType(tokToString(type.type2.builtinType), true);
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
                    return toDType(t).asString();
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


