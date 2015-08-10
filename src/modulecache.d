module modulecache;

import cache;
import dsymbols;
import completionfilter;
import scopecache;
import logger;

import std.allocator;
import std.d.ast;
import std.d.lexer;
import std.d.parser;

import std.typecons;
import std.range;
import std.algorithm;
import std.array;

class ModuleState
{
    import std.file, std.datetime;

    private string _filename;
    private SysTime _modTime;
    private ModuleSymbol _module;
    private CompleterCache _completer;

    bool isValid() const
    {
        return _module !is null;
    }

    private void getModule()
    {
        import std.path;
        auto allocator = scoped!(ParseAllocator)();
        auto cache = StringCache(StringCache.defaultBucketCount);
        LexerConfig config;
        config.fileName = "";
        import std.file : readText;
        auto src = cast(ubyte[])readText(_filename);
        auto tokenArray = getTokensForParser(src, config, &cache);
        auto moduleAst = parseModule(tokenArray, "stdin", allocator, function(a,b,c,d,e){});
        auto visitor = new ModuleVisitor(moduleAst);
        visitor.visit(moduleAst);
        if (visitor._moduleSymbol.name().empty())
        {
            visitor._moduleSymbol.rename(baseName(stripExtension(_filename)));
        }
        _module = visitor._moduleSymbol;
        _module.setFileName(_filename);
    }

    this(string filename)
    {
        debug(wlog) log(filename);
        if (filename.empty())
        {
            return;
        }
        _filename = filename;
        _modTime = timeLastModified(filename);
        _symbolFactory = new SymbolFactory;
        getModule();
        _completer = new CompleterCache;
    }

    this(string moduleName, string[] importPaths)
    {
        import std.path, std.file, std.string, std.array, std.algorithm;
        auto modulePath = split(moduleName, ".");
        auto paths = array(map!(a => buildPath(a ~ modulePath) ~ ".d")(importPaths)) ~ moduleName;
        debug(wlog) log("paths = ", paths);
        auto validPaths = filter!(a => exists(a) && isFile(a))(paths);
        debug(wlog) log("valid paths = ", validPaths);
        string path;
        if (validPaths.empty())
        {
            log("Module ", moduleName, " not found");
        }
        else
        {
            path = validPaths.front();
            if (array(validPaths).length != 1)
            {
                log("Module ", moduleName, " destination is ambiguous: ", validPaths,
                    ". The first path will be used only");
            }
        }
        this(path);
    }

    @property inout(CompleterCache) completer() inout
    {
        return _completer;
    }

    @property inout(ModuleSymbol) dmodule() inout
    {
        return _module;
    }

    DSymbol[] findExact(string id)
    {
        return findExact(_module, id);
    }

    DSymbol[] findExact(DSymbol s, string id)
    {
        return _completer.fetchExact(s, id);
    }

    DSymbol[] findPartial(string part)
    {
        return findPartial(_module, part);
    }

    DSymbol[] findPartial(DSymbol s, string part)
    {
        return _completer.fetchPartial(_module, part);
    }
}

class ModuleCache : LazyCache!(string, ModuleState)
{
    this()
    {
        super(0);
    }

    void addImportPath(string path)
    {
        import std.algorithm, std.file;
        if (canFind(_importPaths, path))
        {
            log("Import path already added");
            return;
        }
        if (!exists(path) || !isDir(path))
        {
            log("Import path does not seem to be valid directory");
            return;
        }
        _importPaths = path ~ _importPaths;
    }

    private string[] _importPaths;

    override ModuleState initialize(string s)
    {
        log("Initialize module ", s);
        auto res = new ModuleState(s, _importPaths);
        return res.isValid() ? res : null;
    }
}

unittest
{
    import std.stdio;
    auto ch = new ModuleCache;
    auto st = ch.get("test/simple.d.txt");
    writeln(st.dmodule.asString());
}

