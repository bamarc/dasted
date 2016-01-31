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
import std.path;
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
    EngineSettings _settings;

    struct EngineSettings
    {
        bool clientSideFiltering = false;
        bool ignoreUnderscore = true;
        bool ignoreCase = true;
    }

public:

    this()
    {
        _factory = new SymbolFactory;
        _astCache = new ASTCache;
        _importVisitor = new ModuleVisitor(_factory, ImportVisible);
        _activeVisitor = new ModuleVisitor(_factory, AllVisible);
        _moduleCache = new ModuleCache(_importVisitor);
    }

    void setFiltering(bool value)
    {
        _settings.clientSideFiltering = value;
    }

    void setIgnoreUnderscore(bool value)
    {
        _settings.ignoreUnderscore = value;
    }

    void setIgnoreCase(bool value)
    {
        _settings.ignoreUnderscore = value;
    }

    void setSource(string fileName, string source, uint revision)
    {
        debug trace("fileName = ", fileName);
        auto res = _astCache.getAST(fileName);
        if (res[0].getModule() !is null && revision != ModuleParser.NO_REVISION
            && revision == res[1])
        {
            _activeAST = res[0];
            return;
        }
        // TODO: set sources only, lazy parsing
        _activeAST = _astCache.updateAST(fileName, source, revision);
        auto mod = _activeAST.getModule();
        _activeVisitor.reset(mod);
        if (_activeVisitor.moduleSymbol().name().empty())
        {
            auto newModuleName = stripExtension(baseName(fileName));
            info("Module ", fileName, " has no module declaration, ",
                 `"`, newModuleName, `" will be used as a name.`);
            _activeVisitor.moduleSymbol().setName(newModuleName);;
        }
        _activeVisitor.moduleSymbol().setModuleCache(_moduleCache);
        _activeVisitor.moduleSymbol().setFileName(fileName);
        _activeVisitor.visitModule(mod);
    }

    inout(ModuleSymbol) activeModule() inout
    {
        debug trace("activeModule ", _activeVisitor.moduleSymbol() is null);
        debug trace("activeModule ", _activeVisitor.moduleSymbol().name());
        return _activeVisitor.moduleSymbol();
    }

    const(Token)[] activeTokens() const
    {
        return _activeAST.tokens();
    }

    void addImportPath(string name)
    {
        _moduleCache.addImportPath(name);
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
        ISymbol[] candidates = scopeSymbol.findSymbol(txt(s.curr));
        while (s.next())
        {
            if (candidates.empty())
            {
                return null;
            }
            if (s.curr.type == tok!".")
            {
                if (candidates.length != 1)
                {
                    return null;
                }
                candidates = candidates.front().dotAccess();
            }
            else if (s.curr.type == tok!"identifier")
            {
                candidates = filter!(a => a.name() == txt(s.curr))(
                    candidates).array();
            }
            else
            {
                return null;
            }
        }
//        debug trace(map!(a => debugString(a))(candidates));
        return candidates.empty() ? null : candidates.front();
    }

    ISymbol[] complete(Offset pos)
    {
        debug trace("offset = ", pos);
        auto parent = findScope(pos);
        auto tokens = getIdentifierChain(getBeforeTokens(pos));
        return complete(parent, tokens, pos);
    }

    /// Basic filtering, can be easily improved
    ISymbol[] filtering(R)(R range, string substring)
    {
        return range.filter!(a => matchNames(a.name(), substring)).array;
    }

    bool matchNames(string a, string b)
    {
        if (_settings.clientSideFiltering)
        {
            return true;
        }
        if (_settings.ignoreCase)
        {
            import std.uni;
            a = toLower(a);
            b = toLower(b);
        }
        if (_settings.ignoreUnderscore)
        {
            import std.string;
            a = a.removechars("_");
            b = b.removechars("_");
        }
        trace ("filter ", a, " ", b);
        return a.startsWith(b);
    }

    ISymbol[] complete(ISymbol scopeSymbol,
        const(Token)[] identifierChain, Offset limit)
    {
        debug trace("chain = ", map!(a => txt(a))(identifierChain),
                    " scope = ", debugString(scopeSymbol));
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
        auto firstSymbText = s.curr.type == tok!"identifier" ? stxt(s.curr)
                                                             : tokToString(s.curr.type);
        debug trace("tok = <", tokToString(s.curr.type), "> ", isExact(), " ",
            firstSymbText, ": ", offset(s.curr));
        ISymbol[] candidates = isExact() ? scopeSymbol.findSymbol(firstSymbText)
                                         : filtering(scopeSymbol.scopeAccess(), firstSymbText);
        while (s.next())
        {
            debug trace("tok = <", tokToString(s.curr.type), "> ", txt(s.curr),
                        ": ", offset(s.curr), ", candidates = ",
                        map!(a => debugString(a))(candidates.take(15)));
            if (candidates.empty())
            {
                return null;
            }
            if (s.curr.type == tok!".")
            {
                if (candidates.length != 1)
                {
                    return null;
                }
                candidates = candidates.front().dotAccess();
            }
            else if (s.curr.type == tok!"identifier")
            {
                candidates = isExact() ?
                    filter!(a => a.name() == stxt(s.curr))(
                        candidates).array()
                    : filtering(candidates, stxt(s.curr));
            }
            else
            {
                return null;
            }
        }
//        debug trace(map!(a => debugString(a))(candidates));
        return candidates;
    }

    ISymbol outline()
    {
        return activeModule();
    }

    Offset[] localUsages(Offset pos)
    {
        auto beforeTokens = getBeforeTokens(pos);
        if (beforeTokens.empty())
        {
            return [];
        }
        string symbTxt = txt(beforeTokens.back());
        auto decl = findDeclaration(pos);
        Offset[] res;
        foreach (t; activeTokens())
        {
            if (t.type == tok!"identifier" && t.text == symbTxt)
            {
                auto candidateSymb = findDeclaration(offset(t) + 1);
                if (decl is candidateSymb)
                {
                    res ~= offset(t);
                }
            }
        }
        return res;
    }
}
