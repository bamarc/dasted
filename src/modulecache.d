module modulecache;

import cache;
import dsymbols.common;
import dsymbols.dmodule;
import completionfilter;
import scopecache;
import logger;

import std.experimental.allocator;
import dparse.ast;
import dparse.lexer;
import dparse.parser;

import std.typecons;
import std.range;
import std.algorithm;
import std.array;
import std.exception;
import std.path;
import std.file;

class ModuleState
{
    import std.file, std.datetime;

    private string _fileName;
    private string _moduleName;
    private SysTime _modTime;
    private ModuleSymbol _module;

    string fileName() const
    {
        return _fileName;
    }

    ModuleSymbol moduleSymbol()
    {
        return _module;
    }

    bool isValid() const
    {
        return _module !is null;
    }

//    private void getModule()
//    {
//        import std.path;
//        auto allocator = scoped!(ParseAllocator)();
//        auto cache = StringCache(StringCache.defaultBucketCount);
//        LexerConfig config;
//        config.fileName = "";
//        import std.file : readText;
//        auto src = cast(ubyte[])readText(_filename);
//        auto tokenArray = getTokensForParser(src, config, &cache);
//        auto moduleAst = parseModule(tokenArray, "stdin", allocator, function(a,b,c,d,e){});
//        auto visitor = new ModuleVisitor(moduleAst);
//        visitor.visit(moduleAst);
//        if (visitor._moduleSymbol.name().empty())
//        {
//            visitor._moduleSymbol.rename(baseName(stripExtension(_filename)));
//        }
//        _module = visitor._moduleSymbol;
//        _module.setFileName(_filename);
//    }

    this(string fileName, string moduleName, ModuleSymbol symb)
    {
        _fileName = fileName;
        _moduleName = moduleName;
        _module = symb;
        _modTime = getModificationTime();
    }

    private void check() const
    {
        enforce(exists(_fileName), "File " ~ _fileName ~
            " for module " ~ _moduleName ~ " does not exist.");
        enforce(isFile(_fileName), "Path " ~ _fileName ~
            " for module " ~ _moduleName ~ " should be a file.");
    }

    private SysTime getModificationTime() const
    {
        check();
        return timeLastModified(_fileName);
    }

    bool needUpdate() const
    {
        return getModificationTime() > _modTime;
    }

//    this(string moduleName, string[] importPaths)
//    {
//        import std.path, std.file, std.string, std.array, std.algorithm;
//        auto modulePath = split(moduleName, ".");
//        auto paths = array(map!(a => buildPath(a ~ modulePath) ~ ".d")(importPaths)) ~ moduleName;
//        debug(wlog) log("paths = ", paths);
//        auto validPaths = filter!(a => exists(a) && isFile(a))(paths);
//        debug(wlog) log("valid paths = ", validPaths);
//        string path;
//        if (validPaths.empty())
//        {
//            log("Module ", moduleName, " not found");
//        }
//        else
//        {
//            path = validPaths.front();
//            if (array(validPaths).length != 1)
//            {
//                log("Module ", moduleName, " destination is ambiguous: ", validPaths,
//                    ". The first path will be used only");
//            }
//        }
//        this(path);
//    }
}

class ModuleCache
{
    LRUCache!(string, ModuleState) _cache;
    this()
    {
        _cache = new LRUCache!(string, ModuleState)(16);
    }

    void addImportPath(string path)
    {
        import std.algorithm, std.file;
        if (canFind(_importPaths, path))
        {
            log("Import path already added.");
            return;
        }
        if (!exists(path) || !isDir(path))
        {
            log("Import path does not seem to be valid directory.");
            return;
        }
        _importPaths = path ~ _importPaths;
    }

    ModuleSymbol getModule(string name)
    {
        auto res = _cache.get(name);
        string fileName;
        if (res[1] && !res[0].needUpdate())
        {
            return res[0].moduleSymbol();
        }
        return null;
//        if (!res[1])
//        {
//            return null;
//            auto paths = computeFilePaths(name);
//            if (paths.empty())
//            {
//                log("Module ", name, " not found.");
//                debug log(" Import paths: ", _importPaths);
//                return null;
//            }
//            if (paths.length > 1)
//            {
//                log("Module ", name, " path is ambiguos");
//                debug log(" Possible paths: ", paths);
//            }
//            fileName = paths.front();
//        }
//        else
//        {
//            fileName = res[0].fileName();
//            if (!res[0].needUpdate())
//            {
//                return res[0].moduleSymbol();
//            }
//        }
//        return null;
    }

    string[] computeFilePaths(string moduleName) const
    {
        auto modulePath = split(moduleName, ".");
        auto paths = array(map!(a => buildPath(a ~ modulePath) ~ ".d")(_importPaths)) ~ moduleName;
        auto validPaths = filter!(a => exists(a) && isFile(a))(paths);
        return validPaths.array();
    }

    void updateModule(string name, string fileName, ModuleSymbol s)
    {
        assert(!fileName.empty());
        _cache.set(name, new ModuleState(fileName, name, s));
    }

    private string[] _importPaths;
}

unittest
{
    import std.stdio;
    auto ch = new ModuleCache;
    auto st = ch.getModule("unknownModule");
    assert(st is null);
}

