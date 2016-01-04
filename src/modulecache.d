module modulecache;

import astcache;
import cache;
import dsymbols.common;
import dsymbols.dmodule;
import completionfilter;
import logger;
import modulevisitor;

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
}

class ModuleCache
{
    LRUCache!(string, ModuleState) _cache;
    ASTCache _astCache;
    ModuleVisitor _visitor;

    this(ModuleVisitor visitor)
    {
        _cache = new LRUCache!(string, ModuleState)(16);
        _astCache = new ASTCache;
        _visitor = visitor;
    }

    void addImportPath(string path)
    {
        import std.algorithm, std.file;
        if (canFind(_importPaths, path))
        {
            log("Import path has been already added.");
            return;
        }
        if (!exists(path) || !isDir(path))
        {
            log("Import path does not seem to be a valid directory.");
            return;
        }
        _importPaths = path ~ _importPaths;
    }

    ModuleSymbol getModule(string name)
    {
        auto res = _cache.get(name);
        string fileName;
        if (!res[1])
        {
            auto paths = computeFilePaths(name);
            if (paths.empty())
            {
                log("Module ", name, " not found.");
                debug log(" Import paths: ", _importPaths);
                return null;
            }
            if (paths.length > 1)
            {
                log("Module ", name, " path is ambiguos");
                debug log(" Possible paths: ", paths);
            }
            fileName = paths.front();
        }
        else
        {
            fileName = res[0].fileName();
            if (!res[0].needUpdate())
            {
                return res[0].moduleSymbol();
            }
        }
        return updateModule(name, fileName);
    }

    string[] computeFilePaths(string moduleName) const
    {
        auto modulePath = split(moduleName, ".");
        auto paths = array(map!(a => buildPath(a ~ modulePath) ~ ".d")(_importPaths)) ~ moduleName;
        auto validPaths = filter!(a => exists(a) && isFile(a))(paths);
        return validPaths.array();
    }

    ModuleSymbol updateModule(string name, string fileName)
    {
        assert(!fileName.empty());
        auto res = _astCache.getModule(fileName);
        auto mod = res[0];
        if (mod is null)
        {
            mod = _astCache.updateModule(fileName, readText(fileName));
        }
        _visitor.visitModule(mod);
        auto ms = _visitor.moduleSymbol();
        _cache.set(name, new ModuleState(fileName, name, ms));
        return ms;
    }

    private string[] _importPaths;
}

unittest
{
    import symbolfactory;
    auto ch = new ModuleCache(new ModuleVisitor(new SymbolFactory, AllVisible));
    auto st = ch.getModule("unknownModule");
    assert(st is null);
}

