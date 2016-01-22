module symbolfactory;

import attributeutils;
import dsymbols;
import logger;
import tokenutils;

import dparse.ast;
import dparse.lexer;
import dparse.parser;

import std.algorithm;
import std.array;
import std.experimental.allocator;

struct SymbolState
{
    ModuleSymbol moduleSymbol;
    AttributeList attributes;
}

private VariableSymbol[] toVariableList(const(Parameters) params)
{
    if (params is null)
    {
        return null;
    }

    return params.parameters.map!(a => new VariableSymbol(txt(a.name), offset(a.name),
                                                          toDType(a.type))).array;
}

class SymbolFactory
{
    ModuleSymbol create(const Module mod)
    {
        debug trace();
        string[] name = txtChain(safeNull(mod).moduleDeclaration.moduleName.get);
        Offset offset = offsetChain(safeNull(mod).moduleDeclaration.moduleName.get);

        return new ModuleSymbol(name, offset);
    }

    ImportSymbol[] create(const ImportDeclaration decl, SymbolState state)
    {
        ImportSymbol[] res;
        foreach (imp; decl.singleImports)
        {
            if (imp !is null)
            {
                res ~= create(imp, state);
            }
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
                baseClasses ~= toDType(safeNull(item).type2.get);
            }
        }
        return new ClassSymbol(txt(decl.name), offset(decl.name),
            fromBlock(safeNull(decl).structBody.get), baseClasses);
    }

    FunctionSymbol create(const FunctionDeclaration decl, SymbolState state)
    {
        import std.typecons;
        Rebindable!(const(BlockStatement)) st;

        st = safeNull(decl).functionBody.blockStatement.get;
        if (st.get is null)
        {
            st = safeNull(decl).functionBody.bodyStatement.blockStatement.get;
        }
        return new FunctionSymbol(txt(decl.name), offset(decl.name),
            fromBlock(st.get), toDType(decl.returnType), toVariableList(decl.parameters));
    }

    StructSymbol create(const StructDeclaration decl, SymbolState state)
    {
        return new StructSymbol(txt(decl.name), offset(decl.name),
            fromBlock(safeNull(decl).structBody.get));
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
            fromBlock(safeNull(decl).structBody.get));
    }

    EnumSymbol create(const EnumDeclaration decl, SymbolState state)
    {
        return new EnumSymbol(txt(decl.name), offset(decl.name),
            fromBlock(safeNull(decl).enumBody.get));
    }

    EnumVariableSymbol create(const EnumMember mem, SymbolState state)
    {
        return new EnumVariableSymbol(txt(mem.name), offset(mem.name));
    }

    DBlock create(const Unittest test, SymbolState state)
    {
        return new DBlock(fromBlock(safeNull(test).blockStatement.get));
    }
}
