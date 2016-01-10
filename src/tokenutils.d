module tokenutils;

import dsymbols.common;

public import dparse.ast;

import dparse.lexer;
import dparse.parser;

import std.algorithm;
import std.array;


string txt(Token t)
{
    return t.text.idup;
}

string tokToString(IdType t)
{
    return str(t);
}

Offset offset(Token t)
{
    return cast(Offset)t.index;
}

string[] txtChain(const IdentifierChain chain)
{
    return chain is null ? null
        : map!(a => txt(a))(chain.identifiers).array();
}

Offset offsetChain(const IdentifierChain chain)
{
    return chain is null || chain.identifiers.empty() ? BadOffset
        : offset(chain.identifiers.front());
}

string joinChain(string[] chain)
{
    return join(chain, '.');
}

ScopeBlock fromBlock(Block)(const Block bs)
    if (is(Block == BlockStatement) || is(Block == StructBody))
{
    return bs is null ? ScopeBlock()
        : ScopeBlock(cast(Offset)bs.startLocation,
        cast(Offset)bs.endLocation);
}

const(Token)[] getIdentifierChain(R)(R range)
{
    bool eligible(const(Token) t)
    {
        return t.type == tok!"identifier" || t.type == tok!".";
    }
    typeof(return) res;
    while (!range.empty() && eligible(range.back()))
    {
        res ~= range.back();
        range.popBack();
    }
    return res;
}

struct TokenStream
{
    private const(Token)[] _tokens;
    private Token _next;

    this(const(Token)[] tokens)
    {
        _tokens = tokens;
        next();
    }

    @property ref const(Token) curr() const
    {
        return _next;
    }

    bool next()
    {
        if (!hasNext())
        {
            return false;
        }
        _next = _tokens.back();
        _tokens.popBack();
        return true;
    }

    bool hasNext() const
    {
        return !_tokens.empty();
    }
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
                result ~= (join(array(map!(a => a.type is null ?
                    "AssignExpression" : typeToString(a.type))
                    (ta.templateArgumentList.items)), ", "));
            }
            return result;
        }
        return DType(array(map!(a => asString(a))(chain)));
    }
    return DType();
}
