module astcache;

import cache;
import moduleparser;

import dsymbols.common;

import dparse.ast;
import std.typecons;

class ASTCache
{
    alias CacheImpl = LRUCache!(string, ModuleParser);
    private CacheImpl _cache;

    this()
    {
        _cache = new CacheImpl(8);
    }

    Tuple!(Module, uint) getModule(string fileName)
    {
        auto res = _cache.get(fileName);
        return tuple(res[0].getModule(), res[0].revision());
    }

    Module updateModule(string fileName, string src,
        uint rev = ModuleParser.NO_REVISION)
    {
        auto parser = ModuleParser(src, rev);
        _cache.set(fileName, parser);
        return parser.getModule();
    }

}
