module convert;

import std.d.ast;
import std.d.lexer;
import std.d.parser;
import std.d.formatter;

auto toSymbol(T)(const T node)
{

    class Converter : ASTVisitor
    {
        alias CompletionKind CK;

        void fromToken(const Token t)
        {
            result.name = t.text;
            result.location.cursor = t.index;
        }

        override void visit(const AnonymousEnumMember enumMem)
        {
            fromToken(enumMem.name);
            result.type = CK.enumMember;
            if (enumMem.type !is null)
            {
                auto app = appender!(char[])();
                auto f = new Formatter!(typeof(app))(app);
                f.format(enumMem.type);
                result.typeName = app.data.idup;
            }
        }

        override void visit(const ClassDeclaration classDec)
        {
            fromToken(classDec.name);
            result.type = CK.className;
            classDec.accept(this);
        }

        override void visit(const EnumDeclaration enumDec)
        {
            fromToken(enumDec.name);
            result.type = CK.enumName;
            if (enumDec.type !is null)
            {
                auto app = appender!(char[])();
                auto f = new Formatter!(typeof(app))(app);
                f.format(enumDec.type);
                result.typeName = app.data.idup;
            }
        }

        override void visit(const EnumMember enumMem)
        {
            fromToken(enumMem.name);
            result.type = CK.enumMember;
            if (enumMem.type !is null)
            {
                auto app = appender!(char[])();
                auto f = new Formatter!(typeof(app))(app);
                f.format(enumMem.type);
                result.typeName = app.data.idup;
            }
        }

        override void visit(const FunctionDeclaration functionDec)
        {
            fromToken(functionDec.name);
            result.type = CK.functionName;
            auto app = appender!(char[])();
            if (functionDec.hasAuto)
            {
                result.typeName = "auto";
            }
            if (functionDec.hasRef)
            {
                result.qualifiers = ["ref"];
            }
            if (functionDec.returnType !is null)
            {
                auto f = new Formatter!(typeof(app))(app);
                f.format(functionDec.returnType);
                result.typeName = app.data.idup;
            }
            if (functionDec.parameters !is null)
            {
                auto f = new Formatter!(typeof(app))(app);
                f.format(functionDec.parameters);
                result.typeName = app.data.idup;
            }
        }

        override void visit(const InterfaceDeclaration interfaceDec)
        {
            fromToken(interfaceDec.name);
            result.type = CK.className;
            interfaceDec.accept(this);
        }

        override void visit(const StructDeclaration structDec)
        {
            fromToken(structDec.name);
            result.type = CK.structName;
            structDec.accept(this);
        }

        override void visit(const TemplateDeclaration templateDec)
        {
            fromToken(templateDec.name);
            result.type = CK.templateName;
            templateDec.accept(this);
            mixin (visitIfNotNull!(templateParameters, constraint));
        }

        override void visit(const StaticConstructor s)
        {
            static if (__traits(compiles, s.location))
            {
                result.name = "this()";
                result.qualifiers = ["static"];
                result.type = CK.functionName;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const StaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                result.name = "~this()";
                result.qualifiers = ["static"];
                result.type = CK.functionName;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const SharedStaticConstructor s)
        {
            static if (__traits(compiles, s.location))
            {
                result.name = "this()";
                result.qualifiers = ["shared", "static"];
                result.type = CK.functionName;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const SharedStaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                result.name = "~this()";
                result.qualifiers = ["shared", "static"];
                result.type = CK.functionName;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const Constructor c)
        {
            result.name = "this()";
            result.type = CK.functionName;
            result.location.cursor = cast(uint)c.location;
        }

        override void visit(const Destructor c)
        {
            result.name = "~this()";
            result.type = CK.functionName;
            result.location.cursor = cast(uint)c.location;
        }

        override void visit(const Unittest u) {}

        override void visit(const UnionDeclaration unionDec)
        {
            fromToken(unionDec.name);
            result.type = CK.unionName;
            unionDec.accept(this);
        }

        override void visit(const VariableDeclaration variableDec)
        {
            fromToken(variableDec.name);
            result.type = CK.variableName;
            foreach (const Declarator d; variableDec.declarators)
            {
                auto app = appender!(char[])();
                if (variableDeclaration.type !is null)
                {
                    auto f = new Formatter!(typeof(app))(app);
                    f.format(variableDeclaration.type);
                    result.typeName = app.data.idup;
                }
            }
        }

    private:

        Symbol result;

        alias visit = ASTVisitor.visit;
    }



}
