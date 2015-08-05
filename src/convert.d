module convert;

import message_struct;
import dsymbols;

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
        alias message_struct.SymbolType CK;

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

    private:

        Symbol result;

        alias visit = ASTVisitor.visit;

    }

    import std.typecons;
    auto conv = scoped!Converter();
    conv.visit(node);
    return conv.result;
}

ubyte toUbyteType(dsymbols.SymbolType s)
{
    switch (s)
    {
    default:
    case dsymbols.SymbolType.NO_TYPE:   return '?';
    case dsymbols.SymbolType.CLASS:     return 'c';
    case dsymbols.SymbolType.INTERFACE: return 'i';
    case dsymbols.SymbolType.STRUCT:    return 's';
    case dsymbols.SymbolType.UNION:     return 'u';
    case dsymbols.SymbolType.FUNC:      return 'f';
    case dsymbols.SymbolType.TEMPLATE:  return 't';
    case dsymbols.SymbolType.MODULE:    return 'M';
    case dsymbols.SymbolType.PACKAGE:   return 'P';
    case dsymbols.SymbolType.ENUM:      return 'g';
    case dsymbols.SymbolType.ENUM_VAR:  return 'e';
    case dsymbols.SymbolType.VAR:       return 'v';
    }
}

Symbol from(const(DSymbol) symbol)
in
{
    assert(symbol !is null);
}
body
{
    Symbol s;
    s.type = symbol.symbolType().toUbyteType();
    s.location.filename = symbol.fileName();
    if (s.location.filename.empty())
    {
        s.location.filename = "std";
    }
    s.location.cursor = symbol.position.offset;
    s.name = symbol.name();
    s.typeName = symbol.type().asString();
    return s;
}
