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

struct ScopeBlock
{
    uint begin = uint.max;
    uint end = uint.max;
    bool isValid()
    {
        return begin != this.init.begin && end != this.init.end;
    }
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
    abstract void addSymbol(DSymbol symbol);
    abstract void injectSymbol(DSymbol symbol);
    abstract string name() const;
    abstract string type() const;
    SymbolType symbolType() const
    {
        return _symbolType;
    }
    ScopeBlock inScope() const
    {
        return ScopeBlock();
    }
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


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }
}

class StructSymbol : ClassSymbol
{
    this()
    {
        _symbolType = SymbolType.STRUCT;
    }
}

class UnionSymbol : ClassSymbol
{
    this()
    {
        _symbolType = SymbolType.UNION;
    }
}

class FuncSymbol : DSymbol
{
    this()
    {
        super(SymbolType.FUNC);
    }
    DSymbol[] _children;
    DSymbol[] _adopted;

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

class ModuleSymbol : ClassSymbol
{
    this()
    {
        _symbolType = SymbolType.MODULE;
    }
}

class PackageSymbol : ClassSymbol
{
    this()
    {
        _symbolType = SymbolType.PACKAGE;
    }
}

class EnumSymbol : DSymbol
{
    this()
    {
        _symbolType = SymbolType.ENUM;
    }

    DSymbol[] _children;

    override DSymbol[] dotAccess()
    {
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        return [];
    }

    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        return;
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

class EnumVarSymbol : VarSymbol
{
    this()
    {
        _symbolType = SymbolType.ENUM_VAR;
    }
}

