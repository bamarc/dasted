module dsymbols.dfunction;

import dsymbols.common;

import std.array;
import std.algorithm;

class FunctionSymbol : DASTSymbol!(SymbolType.FUNC, FunctionDeclaration)
{
    this(const NodeType decl)
    {
        super(decl);

        info.name = decl.name.text;
        info.position.offset = cast(Offset)decl.name.index;
    }

    override DSymbol[] dotAccess() { return []; }

    override DSymbol[] scopeAccess()
    {
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }
}
