module symbolfactory;

import attributeutils;
import dsymbols;
import logger;
import tokenutils;

import dparse.ast;
import dparse.lexer;
import dparse.parser;

import std.experimental.allocator;

struct SymbolState
{
    ModuleSymbol moduleSymbol;
    AttributeList attributes;
}

class SymbolFactory
{
    ModuleSymbol create(const Module mod)
    {
        debug trace();
        string[] name = mod.moduleDeclaration is null ?
            null : txtChain(mod.moduleDeclaration.moduleName);
        Offset offset = mod.moduleDeclaration is null ?
            BadOffset : offsetChain(mod.moduleDeclaration.moduleName);

        return new ModuleSymbol(name, offset);
    }

    ImportSymbol[] create(const ImportDeclaration decl, SymbolState attrs)
    {
        ImportSymbol[] res;
        foreach (imp; decl.singleImports)
        {
            res ~= create(imp, attrs);
        }
        return res;
    }

    ImportSymbol create(const SingleImport imp, SymbolState state)
    {
        return new ImportSymbol(txtChain(imp.identifierChain),
                                txt(imp.rename),
                                offset(imp.rename),
                                state.moduleSymbol,
                                getVisibility(Visibility.PRIVATE, state.attributes));
    }

    ClassSymbol create(const ClassDeclaration decl, SymbolState state)
    {
        DType[] baseClasses;
        if (decl.baseClassList !is null)
        {
            debug trace("create Class ", decl.baseClassList.items.length);
            foreach (item; decl.baseClassList.items)
            {
                baseClasses ~= toDType(item.type2);
            }
        }
        return new ClassSymbol(txt(decl.name), offset(decl.name),
            fromBlock(decl.structBody), baseClasses);
    }

    FunctionSymbol create(const FunctionDeclaration decl, SymbolState state)
    {
        import std.typecons;
        Rebindable!(const(BlockStatement)) st;
        st = safeNull(decl).functionBody.bodyStatement.blockStatement.get;
        return new FunctionSymbol(txt(decl.name), offset(decl.name),
            fromBlock(st.get));
    }

    StructSymbol create(const StructDeclaration decl, SymbolState state)
    {
        return new StructSymbol(txt(decl.name), offset(decl.name),
            fromBlock(safeNull(decl).structBody));
    }

    VariableSymbol[] create(const VariableDeclaration decl, SymbolState state)
    {
        VariableSymbol[] res;
        DType dtype = toDType(decl.type);
        foreach (d; decl.declarators)
        {
            res ~= new VariableSymbol(txt(d.name), offset(d.name), dtype);
        }
        return res;
    }

    UnionSymbol create(const UnionDeclaration decl, SymbolState state)
    {
        return new UnionSymbol(txt(decl.name), offset(decl.name),
            fromBlock(safeNull(decl).structBody));
    }

    DBlock create(const Unittest test, SymbolState state)
    {
        return new DBlock(fromBlock(safeNull(test).blockStatement));
    }
}
