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

    Tuple!(ModuleAST, uint) getAST(string fileName)
    {
        auto res = _cache.get(fileName);
        return tuple(res[0].ast(), res[0].revision());
    }

    ModuleAST updateAST(string fileName, string src,
        uint rev = ModuleParser.NO_REVISION)
    {
        auto parser = ModuleParser(src, rev);
        _cache.set(fileName, parser);
        return parser.ast();
    }
}
