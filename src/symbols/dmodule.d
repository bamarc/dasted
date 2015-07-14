module dsymbols.dmodule;

import dsymbols.common;
import dsymbols.dfunction;


class ModuleSymbol : DASTSymbol!(SymbolType.MODULE, ModuleDeclaration)
{
    this(const ModuleDeclaration decl)
    {
        super(decl);
    }

    private class ModuleFetcher : ASTVisitor
    {

        this()
        {

        }

        mixin NodeVisitor!(ClassDeclaration, _children, false);

//        override void visit(const ClassDeclaration classDec)
//        {
//            addSymbol(new ClassSymbol(classDec));
//        }

//        override void visit(const EnumDeclaration enumDec)
//        {
//            addSymbol(new EnumSymbol(enumDec));
//        }

//        override void visit(const AnonymousEnumMember enumMem)
//        {
//            //addSymbol(new EnumVarSymbol(enumMem));
//        }

//        override void visit(const EnumMember enumMem)
//        {
//            addSymbol(new EnumVarSymbol(enumMem));
//        }

//        override void visit(const FunctionDeclaration functionDec)
//        {
//            addSymbol(new FunctionSymbol(functionDec));
//        }

//        override void visit(const InterfaceDeclaration interfaceDec)
//        {
//            addSymbol(new InterfaceSymbol(interfaceDec));
//        }

//        override void visit(const StructDeclaration structDec)
//        {
//            addSymbol(new StructSymbol(structDec));
//        }

//        override void visit(const TemplateDeclaration templateDeclaration)
//        {
//            addSymbol(new TemplateSymbol(templateDeclaration));
//        }

//        override void visit(const StaticConstructor s)
//        {
//        }

//        override void visit(const StaticDestructor s)
//        {
//        }

//        override void visit(const SharedStaticConstructor s)
//        {
//        }

//        override void visit(const SharedStaticDestructor s)
//        {
//        }

//        override void visit(const Unittest u) {}

//        override void visit(const UnionDeclaration unionDeclaration)
//        {
//            addSymbol(new UnionSymbol(unionDeclaration));
//        }

//        override void visit(const VariableDeclaration variableDeclaration)
//        {
//        }

    private:

        alias visit = ASTVisitor.visit;
    }

    private Module _module;
}
