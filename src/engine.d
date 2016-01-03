module engine;

import astcache;
import dsymbols;
import modulecache;
import modulevisitor;
import moduleparser;
import symbolfactory;


class Engine
{
private:
    SymbolFactory _factory;
    ASTCache _astCache;
    ModuleCache _moduleCache;
    ModuleVisitor _importVisitor;
    ModuleVisitor _activeVisitor;
    ModuleParser* _moduleParser;
public:
    this()
    {
        _factory = new SymbolFactory;
        _astCache = new ASTCache;
        _importVisitor = new ModuleVisitor(_factory, OutlineVisible);
        _activeVisitor = new ModuleVisitor(_factory, AllVisible);
        _moduleCache = new ModuleCache(_importVisitor);
    }


}
