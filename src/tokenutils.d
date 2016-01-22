module tokenutils;

import dsymbols.common;

import dparse.ast;

import dparse.lexer;
import dparse.parser;

import logger;

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
    return chain is null ? []
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
    if (is(Block == BlockStatement) || is(Block == StructBody) || is(Block == EnumBody))
{
    return bs is null ? ScopeBlock()
        : ScopeBlock(cast(Offset)bs.startLocation,
        cast(Offset)bs.endLocation);
}

const(Token)[] getIdentifierChain(R)(R range)
{
    bool eligible(const(Token) t)
    {
        return t.type == tok!"identifier" || t.type == tok!"."
            || t.type == tok!"this";
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

DType toDType(const(Type2) type2)
{
    if (type2 is null)
    {
        return DType();
    }
    if (type2.builtinType != tok!"")
    {
        return DType(tokToString(type2.builtinType), true);
    }
    else if (type2.symbol !is null)
    {
        auto tmp = type2.symbol.identifierOrTemplateChain;
        if (tmp is null)
        {
            return DType();
        }
        auto chain = tmp.identifiersOrTemplateInstances;
        static SimpleDType asSimpleDType(const IdentifierOrTemplateInstance x)
        {
            if (x is null)
            {
                return typeof(return).init;
            }
            import logger;
            debug trace("Simple ", txt(x.identifier));
            if (x.templateInstance is null)
            {
                return SimpleDType(txt(x.identifier));
            }
            auto result = SimpleDType(txt(x.templateInstance.identifier));
            auto ta = x.templateInstance.templateArguments;
            if (ta is null)
            {
                return result;
            }
            if (ta.templateSingleArgument !is null)
            {
                result.templateArguments ~= DType(
                    [SimpleDType(txt(ta.templateSingleArgument.token))]);
            }
            else if (ta.templateArgumentList !is null)
            {
                result.templateArguments =
                    ta.templateArgumentList.items.filter!(a => a !is null)
                    .map!(a => toDType(a.type)).array();
            }
            return result;
        }
        return DType(chain.map!(a => asSimpleDType(a)).array());
    }
    else if (type2.type !is null)
    {
        return toDType(type2.type);
    }
    return DType();
}

DType toDType(const(Type) type)
{
    if (type is null)
    {
        return DType();
    }
    return toDType(type.type2);
}
