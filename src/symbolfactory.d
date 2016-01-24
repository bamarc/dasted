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
import std.typecons;

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

    auto createClassOrInterface(R, T)(const T decl, SymbolState state)
    {
        alias ResultType = R;
        DType[] baseClasses;
        if (decl.baseClassList !is null)
        {
            foreach (item; decl.baseClassList.items)
            {
                baseClasses ~= toDType(safeNull(item).type2.get);
            }
        }
        return new ResultType(txt(decl.name), offset(decl.name),
            fromBlock(safeNull(decl).structBody.get), baseClasses);
    }

    ClassSymbol create(const ClassDeclaration decl, SymbolState state)
    {
        return createClassOrInterface!(ClassSymbol)(decl, state);
    }

    InterfaceSymbol create(const InterfaceDeclaration decl, SymbolState state)
    {
        return createClassOrInterface!(InterfaceSymbol)(decl, state);
    }

    FunctionSymbol create(const FunctionDeclaration decl, SymbolState state)
    {
        debug trace("New Function ", txt(decl.name));
        Rebindable!(const(BlockStatement)) st;

        st = safeNull(decl).functionBody.blockStatement.get;
        if (st.get is null)
        {
            st = safeNull(decl).functionBody.bodyStatement.blockStatement.get;
        }
        return new FunctionSymbol(txt(decl.name), offset(decl.name),
            fromBlock(st.get), toDType(decl.returnType), toVariableList(decl.parameters));
    }

    ConstructorSymbol create(const Constructor decl, SymbolState state)
    {
        return new ConstructorSymbol(cast(Offset)decl.location, fromFunctionBody(decl.functionBody),
                                     toVariableList(decl.parameters));
    }

    DestructorSymbol create(const Destructor decl, SymbolState state)
    {
        return new DestructorSymbol(cast(Offset)decl.index, fromFunctionBody(decl.functionBody));
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

    AliasSymbol create(const AliasDeclaration decl, SymbolState state)
    {
//        debug trace("Alias: ", debugString(decl));
        if (decl.initializers.empty())
        {
            return new AliasSymbol("", 0, toDType(decl.type),
                safeNull(decl).identifierList.identifiers.get.map!(a => txt(a)).array);
        }
        return new AliasSymbol(txt(decl.initializers.front().name),
            offset(decl.initializers.front().name), toDType(decl.initializers.front().type),
            safeNull(decl).identifierList.identifiers.get.map!(a => txt(a)).array);
    }
}
