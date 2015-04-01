module convert;

import message_struct;

import messages;
import std.d.ast;
import std.d.lexer;
import std.d.parser;
import std.d.formatter;

import std.array;

alias message_struct.Symbol Symbol;

auto toSymbol(T)(const T node)
{

    class Converter : ASTVisitor
    {
        alias CompletionKind CK;

        void fromToken(const Token t)
        {
            result.name = t.text;
            result.location.cursor = cast(uint)t.index;
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
            if (classDec.templateParameters !is null)
            {
                visit(classDec.templateParameters);
            }
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
            if (interfaceDec.templateParameters !is null)
            {
                visit(interfaceDec.templateParameters);
            }
        }

        override void visit(const StructDeclaration structDec)
        {
            fromToken(structDec.name);
            result.type = CK.structName;
            if (structDec.templateParameters !is null)
            {
                visit(structDec.templateParameters);
            }
        }

        override void visit(const TemplateDeclaration templateDec)
        {
            fromToken(templateDec.name);
            result.type = CK.templateName;
//            templateDec.accept(this);
            if (templateDec.templateParameters !is null)
            {
                visit(templateDec.templateParameters);
            }
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

        override void visit(const TemplateParameters templateParameters)
        {

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
            result.location.cursor = cast(uint)c.index;
        }

        override void visit(const Unittest u) {}

        override void visit(const UnionDeclaration unionDec)
        {
            fromToken(unionDec.name);
            result.type = CK.unionName;
        }

        override void visit(const VariableDeclaration variableDec)
        {
            result.type = CK.variableName;
            foreach (const Declarator d; variableDec.declarators)
            {
                fromToken(d.name);
                auto app = appender!(char[])();
                if (variableDec.type !is null)
                {
                    auto f = new Formatter!(typeof(app))(app);
                    f.format(variableDec.type);
                    result.typeName = app.data.idup;
                }
            }
        }

    private:

        Symbol result;

        alias visit = ASTVisitor.visit;

    }

    import std.typecons;
    auto conv = scoped!Converter();
    conv.visit(node);
    return conv.result;
}
