module dsymbols.dalias;

import dsymbols.common;
import dsymbols.dsymbolbase;

import logger;

import std.range;

class AliasSymbol : DSymbol
{
    this(string name, Offset position, DType type, string[] tokens)
    {
        _info.name = name;
        _info.type = type;
        _info.position = position;

        _tokens = tokens;
    }

    private auto findAlias(this This)()
    {
        debug trace("Alias type = ", debugString(_info.type));
        if (type != DType.init)
        {
            auto candidates = findType(parent(), _info.type);
            return candidates.empty() ? null : candidates.front();
        }
        return null;
    }

    override SymbolType symbolType() const
    {
        return SymbolType.ALIAS;
    }

    private string[] _tokens;

    override ISymbol[] dotAccess()
    {
        auto s = findAlias();
        return s is null ? null : s.dotAccess();
    }

    override ISymbol[] findSymbol(string name)
    {
        return null;
    }

    override ISymbol[] scopeAccess()
    {
        return null;
    }

    override bool applyTemplateArguments(const DType[] tokens)
    {
        auto s = findAlias();
        return s is null ? false : s.applyTemplateArguments(tokens);
    }

    override bool applyArguments(const DType[] tokens)
    {
        auto s = findAlias();
        return s is null ? false : s.applyArguments(tokens);
    }
}
