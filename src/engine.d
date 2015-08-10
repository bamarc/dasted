module engine;

import dsymbols;
import modulecache;
import completionfilter;
import logger;

import std.algorithm;
import std.typecons;
import std.traits;
import std.range;
import std.exception;

class ModuleVisitor(F) : ASTVisitor
{
    alias Factory = F;

    enum ASTMode
    {
        OUTLINE = 1 << 1,
        FULL = 1 << 0,
        NONE = 0,
    }

    alias ASTModes = BitFlags!ASTMode;
    enum NoModes = ASTModes.init;
    enum AllModes = ~(NoModes);

    mixin template VisitNode(T, ASTModes mode)
    {
        override void visit(const(T) node)
        {
            auto sym = _symbolFactory.create(_symbol, node, _state);
            if (sym[0] is null || !(mode & _mode))
            {
                return;
            }
            debug (print_ast) log(repeat(' ', ast_depth++), T.stringof);
            auto tmp = _symbol;
            assert(sym.length == 1);
            _symbol = sym.front();
            node.accept(this);
            _symbol = tmp;
            debug (print_ast) --ast_depth;
        }
    }

    this(const Module mod, ASTMode mode)
    {
        _moduleSymbol = symbolFactory.create(mod);
        _symbol = _moduleSymbol;
        _symbolFactory = new Factory;
        _mode = mode;
    }

    private DSymbol _symbol = null;
    private ModuleSymbol _moduleSymbol = null;

    mixin VisitNode!(ClassDeclaration, AllModes);
    mixin VisitNode!(StructDeclaration, AllModes);
    mixin VisitNode!(VariableDeclaration, NoModes);
    mixin VisitNode!(FunctionDeclaration, ASTMode.OUTLINE);
    mixin VisitNode!(UnionDeclaration, AllModes);
    mixin VisitNode!(ImportDeclaration, NoModes);
    mixin VisitNode!(Unittest, ASTMode.FULL);

    override void visit(const Declaration decl)
    {
        _state.attributes = decl.attributes;
        decl.accept(this);
        _state.attributes = null;
    }

    private alias visit = ASTVisitor.visit;
    private SymbolState _state;
    private Factory _symbolFactory;
    private ASTMode _mode;
}

class SimpleCompletionEngine
{
    class SymbolFactory
    {
        CachedModuleSymbol create()
        {
            return new CachedModuleSymbol;
        }

        DSymbol[] create(T)(const(T) decl, SymbolState st)
        {
            return fromNode(decl, st);
        }

        PublicImportSymbol[] createFromNode(const ImportDeclaration decl, SymbolState state)
        {
            return array(filter!(a => a !is null)(map!(a => createFromSingleImportNode(a, state))(decl.singleImports)));
        }

        PublicImportSymbol createFromSingleImportNode(const SingleImport imp, SymbolState state)
        {
            return new PublicImportSymbol(imp, state);
        }

        PublicImportSymbol[] create(const(ImportDeclaration) decl, SymbolState st)
        {
            return st.attributes.any!(a => a.attribute == tok!"public") ? createFromNode(decl, st) : null;
        }

        ModuleImportSymbol[] create(const(ImportDeclaration) decl, SymbolState st)
        {
            return createFromNode(decl, st);
        }
    }

    class CachedModuleSymbol : ModuleSymbol
    {
        PublicImportSymbol[] _injected;

        this(const(Module) mod)
        {
            super(mod);
        }

        void inject(PublicImportSymbol imp)
        {
            _injected ~= imp;
        }

        override DSymbol[] dotAccess()
        {
            return _children ~ join(map!(a => a.dotAccess())(_injected));
        }
    }

    public class ModuleImportSymbol : ImportSymbol
    {
        this(const(SingleImport) decl, SymbolState state)
        {
            super(decl, state);
        }

        override DSymbol[] dotAccess()
        {
            auto modState = _moduleCache.get(name());
            if (modState is null)
            {
                return null;
            }

            assert(modState.dmodule !is null);
            return modState.dmodule.dotAccess();
        }
    }

    public class PublicImportSymbol : ImportSymbol
    {
        this(const(SingleImport) decl, SymbolState state)
        {
            super(decl, state);
        }
    }

    DSymbol _scope;
    ModuleCache _modules;
    const(Token)[] _tokens;
    uint _pos;

    void setState(DSymbol scp, const(Token)[] tokens, uint pos)
    {
        _scope = scp;
        _tokens = tokens;
        _pos = pos;
    }

    @property const(Token) curr() const
    {
        return _tokens.back();
    }

    bool next()
    {
        _tokens.popBack();
        return !_tokens.empty();
    }

    bool empty() const
    {
        return _tokens.empty();
    }

    bool needComplete() const
    {
        return _pos <= curr.index + curr.text.length;
    }

    string tokenText(bool shrinkByCursor = true) const
    {
        return shrinkByCursor && needComplete() ? curr.text[0.._pos - curr.index] : curr.text;
    }

    DSymbol[] dotComplete(DSymbol sym)
    {
        return inScopeSymbols(sym);
    }
    DSymbol[] dotComplete(ImportSymbol imp)
    {
        auto state = _modules.get(imp.name());
        if (state is null)
        {
            return null;
        }
        return inScopeSymbols(state.dmodule());
    }
    DSymbol[] dotComplete(VariableSymbol sym)
    {
        auto dtype = sym.type();
        if (dtype.chain.empty())
        {
            return null;
        }
        assert(sym !is null);
        assert(sym.parent !is null);

        auto firstType = dtype.chain.front();
        if (dtype.chain.front().builtin)
        {
            enforce(dtype.chain.length == 1, "Builtin type can not be a part of type chain");
            // todo
            // return standart members like max, init, etc
            return null;
        }
        auto symbols = scopeSymbols(sym.parent);
        foreach (const(SimpleDType) st; dtype.chain)
        {
            auto foundSymbols = find(symbols, st.name);
            if (foundSymbols.length != 1)
            {
                // todo
                // type specializations, various template arguments, etc
                return null;
            }
            symbols = startDotCompletion(foundSymbols);
        }
        return symbols;
    }

    DSymbol[] startDotCompletion(DSymbol[] symbols)
    {
        debug(wlog) trace("SCE: dotCompleteStart");
        return array(joiner(map!(a => a.dotAccess())(symbols)));
    }

    DSymbol[] find(bool exact = true)(DSymbol[] symbols, string txt)
    {
        debug(wlog) trace("SCE: find with ", txt, " (exact = ", exact, ")");
        static if (exact)
        {
            return array(filter!(a => a.name() == txt)(symbols));
        }
        else
        {
            return array(filter!(a => a.name().startsWith(txt))(symbols));
        }
    }

    DSymbol[] find(DSymbol[] symbols, string txt, bool exact)
    {
        return exact ? find!true(symbols, txt) : find!false(symbols, txt);
    }

    DSymbol[] scopeSymbols(DSymbol s)
    {
        return s.scopeAccess();
    }

    DSymbol[] inScopeSymbols(DSymbol s)
    {
        return s.children();
    }

    template FirstArg(F)
    {
        import std.traits;
        alias FirstArg = ParameterTypeTuple!F[0];
    }

    auto dispatchCall(string action, Args...)(Object o, Args args)
    {
        debug(wlog) trace("dispatch ", typeid(o));
        foreach (f; __traits(getOverloads, this, action))
        {
            alias ST = FirstArg!(typeof(f));
            alias UST = Unqual!ST;
            if (typeid(o) == typeid(UST))
            {
                debug(wlog) trace("dispatched ", ST.stringof);
                return f(cast(ST)(o), args);
            }
        }
        static if (__traits(compiles, mixin("this." ~ action ~ "(cast(const DSymbol)(o))")))
        {
            debug(wlog) trace("dispatched const(DSymbol)");
            mixin("return this." ~ action ~ "(cast(DSymbol)(o));");
        }
        else
        {
            debug(wlog) trace("dispatched not");
            return null;
        }
    }

    this(ModuleCache modules)
    {
        _modules = modules;
    }

    DSymbol[] findSymbolChain(bool isFind)
    {
        debug(wlog) trace("SCE: complete ", array(map!(t => t.text)(_tokens)));
        auto scp = _scope;
        if (empty())
        {
            return null;
        }
        if (curr.type == tok!"." && scp.parent !is null)
        {
            scp = scp.parent;
            next();
        }
        debug(wlog) trace("SCE: scope = ", scp.name());
        auto symbols = scopeSymbols(scp);
        debug(wlog) trace("SCE: tokens loop ", empty(), " ", symbols.empty());
        while (!empty() && !symbols.empty())
        {
            debug(wlog) trace("SCE: token type ", tokToString(curr.type));
            switch (curr.type)
            {
            case tok!".": symbols = startDotCompletion(symbols); break;
            case tok!"identifier": symbols = find(symbols, tokenText(!isFind), isFind || !needComplete()); break;
            default: symbols = null;
            }
            next();
        }
        debug(wlog) trace("SCE: result = ", array(map!(a => a.name())(symbols)));
        return symbols;
    }

    DSymbol[] complete()
    {
        return findSymbolChain(false);
    }

    DSymbol[] findDeclaration()
    {
        return findSymbolChain(true);
    }
}
