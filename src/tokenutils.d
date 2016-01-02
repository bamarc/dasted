module tokenutils;

import dsymbols.common;

public import dparse.ast;

import dparse.lexer;
import dparse.parser;

import std.algorithm;
import std.array;


string text(Token t)
{
    return t.text.idup;
}

Offset offset(Token t)
{
    return cast(Offset)t.index;
}

string[] textChain(const IdentifierChain chain)
{
    return chain is null ? null
        : map!(a => text(a))(chain.identifiers).array();
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

ScopeBlock structBlock(const StructBody sb)
{
    return sb is null ? ScopeBlock()
        : ScopeBlock(cast(Offset)sb.startLocation,
                     cast(Offset)sb.endLocation);
}
