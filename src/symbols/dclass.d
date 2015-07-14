module dsymbols.dclass;

import dsymbols.common;

import std.array;
import std.algorithm;



class ClassSymbol : DASTSymbol!(SymbolType.CLASS, ClassDeclaration)
{
    this(const ClassDeclaration decl)
    {
        super(decl);

        info.name = decl.name.text;
        info.position.offset = cast(Offset)decl.name.index;
    }

    override DSymbol[] dotAccess()
    {
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }
}
