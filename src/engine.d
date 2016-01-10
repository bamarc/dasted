module engine;

import astcache;
import dsymbols;
import logger;
import modulecache;
import modulevisitor;
import moduleparser;
import symbolfactory;
import tokenutils;

import std.algorithm;
import std.range;
import std.typecons;

class Engine
{
private:
    SymbolFactory _factory;
    ASTCache _astCache;
    ModuleCache _moduleCache;
    ModuleVisitor _importVisitor;
    ModuleVisitor _activeVisitor;
    ModuleAST _activeAST;
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
        auto res = _astCache.getAST(fileName);
        if (res[0].getModule() !is null && revision == res[1])
        {
            _activeAST = res[0];
            return;
        }
        // TODO: set sources only, lazy parsing
        _activeAST = _astCache.updateAST(fileName, source, revision);
        auto mod = _activeAST.getModule();
        _activeVisitor.reset(mod);
        _activeVisitor.moduleSymbol().setModuleCache(_moduleCache);
        _activeVisitor.visitModule(mod);
    }

    inout(ModuleSymbol) activeModule() inout
    {
        debug trace();
        return _activeVisitor.moduleSymbol();
    }

    const(Token)[] activeTokens() const
    {
        return _activeAST.tokens();
    }

    ISymbol findScope(Offset pos)
    {
        debug trace("offset = ", pos);
        return activeModule().findScope(pos);
    }

    auto getBeforeTokens(Offset pos) const
    {
        return assumeSorted(activeTokens()).lowerBound(pos);
    }

    ISymbol findDeclaration(Offset pos)
    {
        debug trace("offset = ", pos);
        auto parent = findScope(pos);
        auto tokens = getIdentifierChain(getBeforeTokens(pos));
        return findDeclaration(parent, tokens);
    }

    ISymbol findDeclaration(ISymbol scopeSymbol,
        const(Token)[] identifierChain)
    {
        debug trace("chain = ", map!(a => txt(a))(identifierChain));
        if (identifierChain.empty())
        {
            return null;
        }

        auto s = TokenStream(identifierChain);
        if (s.curr.type == tok!".")
        {
            scopeSymbol = activeModule();
            if (!s.next())
            {
                return null;
            }
        }
        ISymbol[] candidates = scopeSymbol.findInScope(txt(s.curr), true);
        while (s.next())
        {
            if (candidates.empty())
            {
                return null;
            }
            auto nextToken = identifierChain.back();
            identifierChain.popBack();
            if (nextToken == tok!".")
            {
                if (candidates.length != 1)
                {
                    return null;
                }
                candidates = candidates.front().dotAccess();
            }
            else if (nextToken == tok!"identifier")
            {
                candidates = filter!(a => a.name() == txt(nextToken))(
                    candidates).array();
            }
            else
            {
                return null;
            }
        }
        return candidates.empty() ? null : candidates.front();
    }

    ISymbol[] complete(Offset pos)
    {
        debug trace("offset = ", pos);
        auto parent = findScope(pos);
        auto tokens = getIdentifierChain(getBeforeTokens(pos));
        return complete(parent, tokens, pos);
    }

    ISymbol[] complete(ISymbol scopeSymbol,
        const(Token)[] identifierChain, Offset limit)
    {
        debug trace("chain = ", map!(a => txt(a))(identifierChain));
        if (identifierChain.empty())
        {
            return null;
        }

        auto s = TokenStream(identifierChain);
        bool isExact()
        {
            return s.hasNext();
        }
        string stxt(const(Token) t)
        {
            auto s = txt(t);
            auto offs = offset(t);
            if (offs + s.length < limit)
            {
                return s;
            }
            return s[0..limit  - offs];
        }
        if (s.curr.type == tok!".")
        {
            scopeSymbol = activeModule();
            if (!s.next())
            {
                return null;
            }
        }
        ISymbol[] candidates = scopeSymbol.findInScope(stxt(s.curr), isExact());
        while (s.next())
        {
            if (candidates.empty())
            {
                return null;
            }
            auto nextToken = identifierChain.back();
            identifierChain.popBack();
            if (nextToken == tok!".")
            {
                if (candidates.length != 1)
                {
                    return null;
                }
                candidates = candidates.front().dotAccess();
            }
            else if (nextToken == tok!"identifier")
            {
                candidates = isExact() ?
                    filter!(a => a.name() == stxt(nextToken))(
                        candidates).array()
                    : filter!(a => a.name().startsWith(stxt(nextToken)))(
                          candidates).array();
            }
            else
            {
                return null;
            }
        }
        return candidates;
    }
}
