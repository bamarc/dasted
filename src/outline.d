module outline;

import message_struct;

import std.array;
import std.typecons;

import std.d.ast;
import std.d.lexer;
import std.d.parser;
import std.d.formatter;
import messages;
import memory.allocators;
import std.allocator;
import string_interning;

alias message_struct.Symbol Symbol;

public Reply!(MessageType.OUTLINE) getOutline(const ref Request!(MessageType.OUTLINE) request)
{

    static string dcopy(string s)
    {
        import std.conv;
        char[] tmp = to!(char[])(s);
        return to!string(tmp);
    }

    class Outliner : ASTVisitor
    {
        alias CompletionKind CK;

        static class OutlineScope
        {
            Symbol[] subsymbols;
            OutlineScope[] children;
            Symbol symbol;
        }

        this()
        {
            global = new OutlineScope;
            current = global;
            scopeStack ~= current;
        }

        override void visit(const ClassDeclaration classDec)
        {
            indent(classDec.name.text, CK.className, classDec.name.index);
            classDec.accept(this);
            outdent();
        }

        override void visit(const EnumDeclaration enumDec)
        {
            indent(enumDec.name.text, CK.enumName, enumDec.name.index);
            enumDec.accept(this);
            outdent();
        }

        override void visit(const AnonymousEnumMember enumMem)
        {
            if (enumMem.type !is null)
            {
                auto app = appender!(char[])();
                auto f = new Formatter!(typeof(app))(app);
                f.format(enumMem.type);
                app.put(' ');
                app.put(enumMem.name.text);
                appendSymbol(app.data.idup, CK.enumMember, enumMem.name.index);
            }
            else
                appendSymbol(enumMem.name.text, CK.enumMember, enumMem.name.index);
        }

        override void visit(const EnumMember enumMem)
        {
            appendSymbol(enumMem.name.text, CK.enumMember, enumMem.name.index);
        }

        override void visit(const FunctionDeclaration functionDec)
        {
            auto app = appender!(char[])();
            if (functionDec.hasAuto)
            app.put("auto ");
            if (functionDec.hasRef)
            app.put("ref ");
            auto f = new Formatter!(typeof(app))(app);
            if (functionDec.returnType !is null)
            f.format(functionDec.returnType);
            app.put(" ");
            app.put(functionDec.name.text);
            f.format(functionDec.parameters);
            appendSymbol(app.data.idup, CK.functionName, functionDec.name.index);
        }

        override void visit(const InterfaceDeclaration interfaceDec)
        {
            indent(interfaceDec.name.text, CK.interfaceName, interfaceDec.name.index);
            interfaceDec.accept(this);
            outdent();
        }

        override void visit(const StructDeclaration structDec)
        {
            indent(structDec.name.text, CK.structName, structDec.name.index);
            structDec.accept(this);
            outdent();
        }

        override void visit(const TemplateDeclaration templateDeclaration)
        {
            indent(templateDeclaration.name.text, CK.templateName, templateDeclaration.name.index);
            templateDeclaration.accept(this);
            outdent();
        }

        override void visit(const StaticConstructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol("static this()", CK.functionName, s.location);
            }
        }

        override void visit(const StaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol("static ~this()", CK.functionName, s.location);
            }
        }

        override void visit(const SharedStaticConstructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol("shared static this()", CK.functionName, s.location);
            }
        }

        override void visit(const SharedStaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol("shared static ~this()", CK.functionName, s.location);
            }
        }

        override void visit(const Constructor c)
        {
            appendSymbol("this()", CK.functionName, c.location);
        }

        override void visit(const Destructor c)
        {
            appendSymbol("~this()", CK.functionName, c.index);
        }

        override void visit(const Unittest u) {}

        override void visit(const UnionDeclaration unionDeclaration)
        {
            indent(unionDeclaration.name.text, CK.unionName, unionDeclaration.name.index);
            unionDeclaration.accept(this);
            outdent();
        }

        override void visit(const VariableDeclaration variableDeclaration)
        {
            foreach (const Declarator d; variableDeclaration.declarators)
            {
                auto app = appender!(char[])();
                if (variableDeclaration.type !is null)
                {
                    auto f = new Formatter!(typeof(app))(app);
                    f.format(variableDeclaration.type);
                }
                app.put(' ');
                app.put(d.name.text);
                appendSymbol(app.data.idup, CK.variableName, d.name.index);
            }
        }

        OutlineScope getResult()
        {
            return global;
        }

    private:

        Symbol createSymbol(string fullname, CompletionKind kind, size_t location)
        {
            Symbol result;
            result.name = dcopy(fullname);
            result.type = kind;
            result.location.cursor = cast(uint)location;
            return result;
        }

        void appendSymbol(string fullname, CompletionKind kind, size_t location)
        {
            current.subsymbols ~= createSymbol(fullname, kind, location);
        }

        void indent(string fullname, CompletionKind kind, size_t location)
        {
            OutlineScope sc = new OutlineScope;
            sc.symbol = createSymbol(fullname, kind, location);
            current.children ~= sc;
            current = sc;
            scopeStack ~= sc;
        }

        void outdent()
        {
            scopeStack.popBack();
            current = scopeStack.back();
        }

        OutlineScope global;

        OutlineScope current;

        OutlineScope[] scopeStack;

        alias visit = ASTVisitor.visit;
    }

    LexerConfig config;
    config.fileName = "";
    auto cache = StringCache(StringCache.defaultBucketCount);
    const(Token)[] tokenArray = getTokensForParser(cast(ubyte[]) request.src,
        config, &cache);
    auto allocator = scoped!(CAllocatorImpl!(BlockAllocator!(1024 * 16)))();
    auto mod = parseModule(tokenArray, internString("stdin"), allocator, function void(a, b, c, d, e){});
    auto outliner = new Outliner;
    outliner.visit(mod);

    Reply!(MessageType.OUTLINE) reply;

    static void mergeScopes(ref Scope s, Outliner.OutlineScope os)
    {
        s.master.name = dcopy(os.symbol.name);
        s.master.type = os.symbol.type;
        s.master.location = os.symbol.location;
        s.symbols = os.subsymbols.dup;
        foreach (cos; os.children)
        {
            s.children ~= Scope();
            mergeScopes(s.children.back(), cos);
        }
    }

    mergeScopes(reply.global, outliner.global);

    return reply;
}
