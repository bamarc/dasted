module symbolfactory;

import dsymbols;
import tokenutils;

import dparse.ast;
import dparse.lexer;
import dparse.parser;

import std.experimental.allocator;

alias AttributeList = const(Attribute)[];

struct AttributeStackGuard
{
    this(AttributeList* stack, AttributeList attr)
    {
        _attributes = stack;
        if (!attr.empty())
        {
            (*_attributes) ~= attr;
            _num = attr.length;
        }
    }

    ~this()
    {
        if (_num > 0)
        {
            (*_attributes) = (*_attributes)[0..$ - _num];
        }
    }
    typeof(AttributeList.init.length) _num;
    AttributeList* _attributes;
}


class SymbolFactory
{
    ISymbol[] create(const Module mod, AttributeList attrs)
    {
        string[] name = mod.moduleDeclaration is null ?
            null : textChain(mod.moduleDeclaration.moduleName);
        Offset offset = mod.moduleDeclaration is null ?
            BadOffset : offsetChain(mod.moduleDeclaration.moduleName);
        return [new ModuleSymbol(name, offset)];
    }

    ISymbol[] create(const ImportDeclaration decl, AttributeList attrs)
    {
        ISymbol[] res;
        foreach (imp; decl.singleImports)
        {
            res ~= create(imp, attrs);
        }
        return res;
    }

    ISymbol[] create(const SingleImport imp, AttributeList attrs)
    {
        return [new ImportSymbol(textChain(imp.identifierChain),
                                 text(imp.rename),
                                 offset(imp.rename))];
    }

    ISymbol[] create(const ClassDeclaration decl, AttributeList attrs)
    {
        return [new ClassSymbol(text(decl.name), offset(decl.name),
            structBlock(decl.structBody))];
    }
}
