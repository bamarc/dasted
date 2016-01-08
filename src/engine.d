module engine;

import astcache;
import dsymbols;
import logger;
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

    void setSource(string fileName, string source, uint revision)
    {
        debug trace("fileName = ", fileName);
        auto res = _astCache.getModule(fileName);
        if (res[0] !is null && revision == res[1])
        {
            return;
        }
        // TODO: set sources only, lazy parsing
        auto mod = _astCache.updateModule(fileName, source, revision);
        _activeVisitor.visitModule(mod);
    }

    inout(ModuleSymbol) activeModule() inout
    {
        debug trace();
        return _activeVisitor.moduleSymbol();
    }

    ISymbol findSymbol(Offset pos)
    {
        debug trace("offset = ", pos);
        return activeModule().findScope(pos);
    }
}
