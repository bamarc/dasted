module convert;

import messages;
import dsymbols;

import dparse.ast;
import dparse.lexer;
import dparse.parser;
import dparse.formatter;

import std.array;

alias messages.MSymbol MSymbol;

auto toSymbol(T)(const T node)
{

    class Converter : ASTVisitor
    {
        alias messages.SymbolType CK;

        void fromToken(const Token t)
        {
            result.name = t.text;
            result.location.cursor = cast(uint)t.index;
        }

        override void visit(const AnonymousEnumMember enumMem)
        {
            fromToken(enumMem.name);
            result.type = CK.ENUM_VARIABLE;
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
            result.type = CK.CLASS;
            if (classDec.templateParameters !is null)
            {
                visit(classDec.templateParameters);
            }
        }

        override void visit(const EnumDeclaration enumDec)
        {
            fromToken(enumDec.name);
            result.type = CK.ENUM;
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
            result.type = CK.ENUM_VARIABLE;
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
            result.type = CK.FUNCTION;
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
            result.type = CK.CLASS;
            if (interfaceDec.templateParameters !is null)
            {
                visit(interfaceDec.templateParameters);
            }
        }

        override void visit(const StructDeclaration structDec)
        {
            fromToken(structDec.name);
            result.type = CK.STRUCT;
            if (structDec.templateParameters !is null)
            {
                visit(structDec.templateParameters);
            }
        }

        override void visit(const TemplateDeclaration templateDec)
        {
            fromToken(templateDec.name);
            result.type = CK.TEMPLATE;
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
                result.type = CK.FUNCTION;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const StaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                result.name = "~this()";
                result.qualifiers = ["static"];
                result.type = CK.FUNCTION;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const SharedStaticConstructor s)
        {
            static if (__traits(compiles, s.location))
            {
                result.name = "this()";
                result.qualifiers = ["shared", "static"];
                result.type = CK.FUNCTION;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const SharedStaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                result.name = "~this()";
                result.qualifiers = ["shared", "static"];
                result.type = CK.FUNCTION;
                result.location.cursor = cast(uint)s.location;
            }
        }

        override void visit(const TemplateParameters templateParameters)
        {

        }

        override void visit(const Constructor c)
        {
            result.name = "this()";
            result.type = CK.FUNCTION;
            result.location.cursor = cast(uint)c.location;
        }

        override void visit(const Destructor c)
        {
            result.name = "~this()";
            result.type = CK.FUNCTION;
            result.location.cursor = cast(uint)c.index;
        }

        override void visit(const Unittest u) {}

        override void visit(const UnionDeclaration unionDec)
        {
            fromToken(unionDec.name);
            result.type = CK.UNION;
        }

    private:

        MSymbol result;

        alias visit = ASTVisitor.visit;

    }

    import std.typecons;
    auto conv = scoped!Converter();
    conv.visit(node);
    return conv.result;
}

messages.SymbolType toUbyteType(dsymbols.SymbolType s)
{
    alias S = messages.SymbolType;
    switch (s)
    {
    default:
    case dsymbols.SymbolType.NO_TYPE:   return S.UNKNOWN;
    case dsymbols.SymbolType.CLASS:     return S.CLASS;
    case dsymbols.SymbolType.INTERFACE: return S.INTERFACE;
    case dsymbols.SymbolType.STRUCT:    return S.STRUCT;
    case dsymbols.SymbolType.UNION:     return S.UNION;
    case dsymbols.SymbolType.FUNC:      return S.FUNCTION;
    case dsymbols.SymbolType.TEMPLATE:  return S.TEMPLATE;
    case dsymbols.SymbolType.MODULE:    return S.MODULE;
    case dsymbols.SymbolType.PACKAGE:   return S.PACKAGE;
    case dsymbols.SymbolType.ENUM:      return S.ENUM;
    case dsymbols.SymbolType.ENUM_VAR:  return S.ENUM_VARIABLE;
    case dsymbols.SymbolType.VAR:       return S.VARIABLE;
    }
}

MSymbol toMSymbol(const(ISymbol) symbol)
{
    MSymbol s;
    if (symbol is null)
    {
        return s;
    }
    s.type = symbol.symbolType().toUbyteType();
    s.location.filename = symbol.fileName();
    if (s.location.filename.empty())
    {
        s.location.filename = "stdin";
    }
    s.location.cursor = symbol.position;
    s.name = symbol.name();
    s.typeName = symbol.type().asString();
    return s;
}

MScope toMScope(const(ISymbol) symbol)
{
    MScope mscope;
    if (symbol is null)
    {
        return mscope;
    }
    mscope.symbol = toMSymbol(symbol);
    foreach (s; symbol.children())
    {
        mscope.children ~= toMScope(s);
    }
    return mscope;
}
