module outline;

import message_struct;
import convert;

import std.array;
import std.typecons;

import std.d.ast;
import std.d.lexer;
import std.d.parser;
import std.d.formatter;
import std.allocator;

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
        alias SymbolType CK;

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
            indent(classDec);
            classDec.accept(this);
            outdent();
        }

        override void visit(const EnumDeclaration enumDec)
        {
            indent(enumDec);
            enumDec.accept(this);
            outdent();
        }

        override void visit(const AnonymousEnumMember enumMem)
        {
            appendSymbol(enumMem);
        }

        override void visit(const EnumMember enumMem)
        {
            appendSymbol(enumMem);
        }

        override void visit(const FunctionDeclaration functionDec)
        {
            appendSymbol(functionDec);
        }

        override void visit(const InterfaceDeclaration interfaceDec)
        {
            indent(interfaceDec);
            interfaceDec.accept(this);
            outdent();
        }

        override void visit(const StructDeclaration structDec)
        {
            indent(structDec);
            structDec.accept(this);
            outdent();
        }

        override void visit(const TemplateDeclaration templateDeclaration)
        {
            indent(templateDeclaration);
            templateDeclaration.accept(this);
            outdent();
        }

        override void visit(const StaticConstructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol(s);
            }
        }

        override void visit(const StaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol(s);
            }
        }

        override void visit(const SharedStaticConstructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol(s);
            }
        }

        override void visit(const SharedStaticDestructor s)
        {
            static if (__traits(compiles, s.location))
            {
                appendSymbol(s);
            }
        }

        override void visit(const Constructor c)
        {
            appendSymbol(c);
        }

        override void visit(const Destructor c)
        {
            appendSymbol(c);
        }

        override void visit(const Unittest u) {}

        override void visit(const UnionDeclaration unionDeclaration)
        {
            indent(unionDeclaration);
            unionDeclaration.accept(this);
            outdent();
        }

        override void visit(const VariableDeclaration variableDeclaration)
        {
            foreach (const Declarator d; variableDeclaration.declarators)
            {
                Symbol s;
                auto app = appender!(char[])();
                if (variableDeclaration.type !is null)
                {
                    auto f = new Formatter!(typeof(app))(app);
                    f.format(variableDeclaration.type);
                    s.typeName = app.data.idup;
                }
                s.name = d.name.text;
                s.location.cursor = cast(uint)d.name.index;
                s.type = CK.variableName;
                appendSymbol(s);
            }
        }

        OutlineScope getResult()
        {
            return global;
        }

    private:

        string makeString(const TemplateTupleParameter ttp)
        {
            return dcopy(ttp.identifier.text);
        }

        string makeString(const TemplateTypeParameter ttp)
        {
            return dcopy(ttp.identifier.text);
        }

        string makeString(const TemplateThisParameter ttp)
        {
            return makeString(ttp.templateTypeParameter);
        }

        string makeString(const TemplateValueParameter tvp)
        {
            return dcopy(tvp.identifier.text);
        }

        string[] makeString(const TemplateParameters tp)
        {
            string[] result;
            if (tp is null || tp.templateParameterList is null)
            {
                return result;
            }

            foreach (i; tp.templateParameterList.items)
            {
                string str;
                if (i.templateTupleParameter !is null)
                {
                    str ~= makeString(i.templateTupleParameter);
                }
                else if (i.templateThisParameter !is null)
                {
                    str ~= makeString(i.templateThisParameter);
                }
                else if (i.templateTypeParameter !is null)
                {
                    str ~= makeString(i.templateTypeParameter);
                }
                else if (i.templateValueParameter !is null)
                {
                    str ~= makeString(i.templateValueParameter);
                }

                result ~= str;
            }
            return result;
        }

        Symbol createSymbol(T)(const ref T node)
        {
            return toSymbol(node);
        }

        Symbol createSymbol(ref Symbol s)
        {
            return s;
        }

        void appendSymbol(Args...)(Args args)
        {
            current.subsymbols ~= createSymbol(args);
        }

        void indent(Args...)(Args args)
        {
            OutlineScope sc = new OutlineScope;
            sc.symbol = createSymbol(args);
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
    auto allocator = scoped!(ParseAllocator)();
    auto mod = parseModule(tokenArray, "stdin", allocator, function void(a, b, c, d, e){});
    auto outliner = new Outliner;
    outliner.visit(mod);

    Reply!(MessageType.OUTLINE) reply;

    static void symCopy(ref Symbol s)
    {
        import std.algorithm;
        s.name = dcopy(s.name);
        s.templateParameters = array(map!(s => dcopy(s))(s.templateParameters));
        s.typeName = dcopy(s.typeName);
        s.qualifiers = array(map!(s => dcopy(s))(s.qualifiers));
        s.parameters = array(map!(s => dcopy(s))(s.parameters));
        s.doc = dcopy(s.doc);
    }

    static void mergeScopes(ref Scope s, Outliner.OutlineScope os)
    {
        s.master = os.symbol;
        s.symbols = os.subsymbols.dup;
        symCopy(s.master);
        foreach (ss; s.symbols)
        {
            symCopy(ss);
        }
        foreach (cos; os.children)
        {
            s.children ~= Scope();
            mergeScopes(s.children.back(), cos);
        }

    }

    mergeScopes(reply.global, outliner.global);

    return reply;
}
