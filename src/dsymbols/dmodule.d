module dsymbols.dmodule;

import dsymbols.common;
import dsymbols.dsymbolbase;
import dsymbols.dfunction;

import astcache;
import logger;
import modulecache;
import scopemap;

import std.array;
import std.algorithm;
import std.exception;


class ModuleSymbol : TypedSymbol!(SymbolType.MODULE)
{
    this(string[] name, Offset pos)
    {
        _nameChain = name;
        _info.name = join(name, ".");
        _info.position = pos;

        scopes = new ScopeMap;
        debug trace("pos = ", pos, ", name = ", name);
    }

    void setName(string name)
    {
        debug trace("name = ", name);
        _info.name = name;
        _nameChain = [name];
        _info.position = 0;
    }

    void setFileName(string fileName)
    {
        _fileName = fileName;
    }

    override string fileName() const
    {
        return _fileName;
    }

    void addScope(ISymbol s)
    {
        scopes.add(s);
    }

    ISymbol findScope(Offset pos)
    {
        debug trace("pos = ", pos);
        return scopes.findScope(pos);
    }

    inout(ModuleCache) moduleCache() inout
    {
        return _moduleCache;
    }

    void setModuleCache(ModuleCache c)
    {
        _moduleCache = c;
    }

    string _fileName;
    string[] _nameChain;
    ScopeMap scopes;
    ModuleCache _moduleCache;
}
