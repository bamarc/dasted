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
