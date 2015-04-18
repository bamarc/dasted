module dsymbols;

import std.d.lexer;

import string_interning;

import std.algorithm;
import std.array;

enum SymbolType
{
    NO_TYPE = 0,
    CLASS,
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
    abstract string name();
    abstract string type();
    abstract SymbolType symbolType();
}

class ClassSymbol : DSymbol
{
    this()
    {
        super(SymbolType.CLASS);
    }

    DSymbol[] _children;
    DSymbol[] _adopted;

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
}

class VarSymbol : DSymbol
{
    this()
    {
        super(SymbolType.VAR);
    }

    DSymbol _type;

    override DSymbol[] dotAccess()
    {
        return _type.dotAccess();
    }

    override DSymbol[] scopeAccess()
    {
        return [];
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }

}

