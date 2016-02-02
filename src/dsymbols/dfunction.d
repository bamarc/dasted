module dsymbols.dfunction;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dvariable;

import logger;

import std.array;
import std.algorithm;
import std.conv;

class FunctionSymbol : TypedSymbol!(SymbolType.FUNC)
{
    this(string name, Offset pos, ScopeBlock block, DType returnType, VariableSymbol[] args)
    {
        _info.name = name;
        _info.position = pos;
        _info.scopeBlock = block;

        _args = args;
        foreach (a; _args)
        {
            a.parent = this;
        }
        _returnType = returnType;
    }

    override ISymbol[] dotAccess()
    {
        return null;
    }

    override ParameterList parameters() const
    {
        return _args.map!(a => const(Parameter)(a.name(), a.type())).array;
    }

    VariableSymbol[] _args;
    DType _returnType;
}

class ConstructorSymbol : FunctionSymbol
{
    this(Offset pos, ScopeBlock block, VariableSymbol[] args)
    {
        super("this", pos, block, DType.init, args);
    }

    override void addToParent(ISymbol)
    {

    }
}

class DestructorSymbol : FunctionSymbol
{
    this(Offset pos, ScopeBlock block)
    {
        super("~this", pos, block, DType.init, null);
    }
}
