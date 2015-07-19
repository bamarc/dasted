module dmodulecache;

import cache;

import memory.allocators;
import std.allocator;
import std.d.ast;
import std.d.lexer;
import std.d.parser;

import string_interning;

import std.typecons;
import std.range;

import dsymbols;
import completionfilter;

debug (print_ast)
{
    import std.stdio;
    uint ast_depth = 0;
}


class ModuleState
{
    import std.file, std.datetime;

    private string _filename;
    private SysTime _modTime;
    private ModuleSymbol _module;
    private CompletionCache!SortedFilter _completions;

    private void getModule()
    {
        import std.path;
        auto allocator = scoped!(CAllocatorImpl!(BlockAllocator!(1024 * 16)))();
        auto cache = StringCache(StringCache.defaultBucketCount);
        LexerConfig config;
        config.fileName = "";
        import std.file : readText;
        auto src = cast(ubyte[])readText(_filename);
        auto tokenArray = getTokensForParser(src, config, &cache);
//        auto beforeTokens = assumeSorted(tokenArray).lowerBound(pos);
        auto moduleAst = parseModule(tokenArray, internString("stdin"), allocator, function(a,b,c,d,e){});
        auto visitor = scoped!ModuleVisitor(moduleAst);
        visitor.visit(moduleAst);
        if (visitor._moduleSymbol.name().empty())
        {
            visitor._moduleSymbol.rename(baseName(stripExtension(_filename)));
        }
        _module = visitor._moduleSymbol;
    }

    static void child(T, R)(const T node, R parent, R symbol)
    {
        parent.add(symbol);
    }

    static void adopt(T, R)(const T node, R parent, R symbol)
    {
        parent.inject(symbol);
    }

    mixin template VisitNode(T, alias action, Flag!"Stop" stop)
    {
        override void visit(const T node)
        {
            alias TypeOfSymbol = NodeToSymbol!T;
            auto sym = fromNode(node);
            debug (print_ast) writeln(repeat(' ', ast_depth++), T.stringof);
            foreach (DSymbol s; sym) action(node, _symbol, s);
            static if(!stop)
            {
                auto tmp = _symbol;
                _symbol = sym.front();
                node.accept(this);
                _symbol = tmp;
            }
            debug (print_ast) --ast_depth;
        }
    }

    static class ModuleVisitor : ASTVisitor
    {
        this(const Module mod)
        {
            _moduleSymbol = new ModuleSymbol(mod);
            _symbol = _moduleSymbol;
        }

        private DSymbol _symbol = null;
        private ModuleSymbol _moduleSymbol = null;
        mixin VisitNode!(ClassDeclaration, child, No.Stop);
        mixin VisitNode!(StructDeclaration, child, No.Stop);
        mixin VisitNode!(VariableDeclaration, child, Yes.Stop);
        mixin VisitNode!(FunctionDeclaration, child, Yes.Stop);

        private alias visit = ASTVisitor.visit;
    }


    this(string filename)
    {
        _filename = filename;
        _modTime = timeLastModified(filename);
        getModule();
        _completions = new CompletionCache!SortedFilter;
    }
}

class ModuleCache : LazyCache!(string, ModuleState)
{
    this()
    {
        super(0);
    }

    override ModuleState initialize(const(string) s)
    {
        return new ModuleState(s);
    }
}

unittest
{
    import std.stdio;
    auto ch = new ModuleCache;
    ch.add("test/simple.d.txt");
    writeln(ch.get("test/simple.d.txt").asString());
}

