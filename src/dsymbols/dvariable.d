 module dsymbols.dvariable;

import dsymbols.common;
import dsymbols.dsymbolbase;

import logger;

import std.algorithm;
import std.array;
import std.range;


class VariableSymbol : TypedSymbol!(SymbolType.VAR)
{
    this(string name, Offset pos, DType type)
    {
        _info.name = name;
        _info.type = type;
        _info.position = pos;
    }

    override ISymbol[] dotAccess()
    {
        debug trace();
        if (type.evaluate)
        {
            throw new Exception("Type evaluation not implemented.");
        }

        if (type.builtin || type.chain.empty())
        {
            return null;
        }

        auto declarations = parent().findInScope(type.chain.front().name, true);
        foreach (dotType; type.chain.dropOne())
        {
            debug trace("declarations = ", map!(a => a.name())(declarations));
            if (declarations.empty())
            {
                return null;
            }
            declarations = filter!(a => a.name() == dotType.name)(
                declarations.front().dotAccess()).array();
        }
        if (declarations.empty())
        {
            return null;
        }
        debug trace("dot access for ", debugString(declarations.front()));
        return declarations.front().dotAccess();
    }
}

class EnumVariableSymbol : TypedSymbol!(SymbolType.ENUM)
{
    this(string name)
    {
       _info.name = name;
    }
}
