module dsymbols;

import std.d.lexer;
import std.d.ast;

import string_interning;

import std.algorithm;
import std.array;
import std.typecons;

enum SymbolType
{
    NO_TYPE = 0,
    CLASS,
    INTERFACE,
    STRUCT,
    UNION,
    FUNC,
    TEMPLATE,
    MODULE,
    PACKAGE,
    ENUM,
    ENUM_VAR,
    VAR,
}

struct ScopeBlock
{
    uint begin = uint.max;
    uint end = uint.max;
    bool isValid()
    {
        return begin != this.init.begin || end != this.init.end;
    }
}

bool isInScope(DSymbol sc, DSymbol sym)
{
    auto scb = sc.scopeBlock();
    auto pos = sym.offset();
    return scb.isValid() && scb.begin < pos && scb.end > pos;
}

class DSymbol
{
    protected SymbolType _symbolType = SymbolType.NO_TYPE;
    this(SymbolType t = SymbolType.NO_TYPE)
    {
        _symbolType = t;
    }

    abstract DSymbol[] dotAccess();
    abstract DSymbol[] scopeAccess();
    abstract DSymbol[] templateInstantiation(const Token[] tokens);
    abstract DSymbol[] applyArguments(const Token[] tokens);
    abstract void addSymbol(DSymbol symbol);
    abstract void injectSymbol(DSymbol symbol);
    abstract string name() const;
    abstract string type() const;
    SymbolType symbolType() const
    {
        return _symbolType;
    }
    abstract ubyte offset() const;
    ScopeBlock scopeBlock() const
    {
        return ScopeBlock();
    }

    private bool _fetched = false;

    protected abstract void doFetch();

    protected final void fetch()
    {
        if (_fetched)
        {
            return;
        }
        _fetched = true;
        doFetch();
    }
}

class ClassSymbol : DSymbol
{
    this(const ClassDeclaration decl)
    {
        _decl = decl;
        super(SymbolType.CLASS);
    }

    DSymbol[] _children;
    DSymbol[] _adopted;

    override DSymbol[] dotAccess()
    {
        fetch();
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        fetch();
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }

    override string name() const
    {
        return _decl.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }



    private const ClassDeclaration _decl;
}

class InterfaceSymbol : DSymbol
{
    this(const InterfaceDeclaration decl)
    {
        _decl = decl;
        super(SymbolType.CLASS);
    }

    DSymbol[] _children;
    DSymbol[] _adopted;

    override DSymbol[] dotAccess()
    {
        fetch();
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        fetch();
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }

    override string name() const
    {
        return _decl.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }

    private const InterfaceDeclaration _decl;
}

class StructSymbol : DSymbol
{
    this(const StructDeclaration decl)
    {
        _decl = decl;
        _symbolType = SymbolType.STRUCT;
    }

    DSymbol[] _children;
    DSymbol[] _adopted;

    override DSymbol[] dotAccess()
    {
        fetch();
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        fetch();
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }

    override string name() const
    {
        return _decl.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }

    private const StructDeclaration _decl;
}

class UnionSymbol : DSymbol
{
    this(const UnionDeclaration decl)
    {
        _decl = decl;
        _symbolType = SymbolType.STRUCT;
    }

    DSymbol[] _children;
    DSymbol[] _adopted;

    override DSymbol[] dotAccess()
    {
        fetch();
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        fetch();
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }

    override string name() const
    {
        return _decl.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }

    private const UnionDeclaration _decl;
}

class FuncSymbol : DSymbol
{
    this(const FunctionDeclaration decl)
    {
        _decl = decl;
        super(SymbolType.FUNC);
    }
    DSymbol[] _children;
    DSymbol[] _adopted;

    override DSymbol[] dotAccess() { return []; }

    override DSymbol[] scopeAccess()
    {
        fetch();
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }

    override string name() const
    {
        return _decl.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }

    const FunctionDeclaration _decl;
}

class TemplateSymbol : DSymbol
{
    this(const TemplateDeclaration decl)
    {
        _decl = decl;
        _symbolType = SymbolType.STRUCT;
    }

    DSymbol[] _children;
    DSymbol[] _adopted;

    override DSymbol[] dotAccess()
    {
        fetch();
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        fetch();
        return _children ~ join(map!(a => a.dotAccess())(_adopted));
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }


    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        _adopted ~= symbol;
    }

    override string name() const
    {
        return _decl.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }

    private const TemplateDeclaration _decl;
}

class ModuleSymbol : ClassSymbol
{
    this()
    {
        super(null);
        _symbolType = SymbolType.MODULE;
    }

    void setModule(Module m)
    {
        _module = m;
    }

    override ScopeBlock scopeBlock() const
    {
        return ScopeBlock(0, ScopeBlock.end.max);
    }

    private class ModuleFetcher : ASTVisitor
    {

        this()
        {

        }

        override void visit(const ClassDeclaration classDec)
        {
            addSymbol(new ClassSymbol(classDec));
        }

        override void visit(const EnumDeclaration enumDec)
        {
            addSymbol(new EnumSymbol(enumDec));
        }

        override void visit(const AnonymousEnumMember enumMem)
        {
            //addSymbol(new EnumVarSymbol(enumMem));
        }

        override void visit(const EnumMember enumMem)
        {
            addSymbol(new EnumVarSymbol(enumMem));
        }

        override void visit(const FunctionDeclaration functionDec)
        {
            addSymbol(new FuncSymbol(functionDec));
        }

        override void visit(const InterfaceDeclaration interfaceDec)
        {
            addSymbol(new InterfaceSymbol(interfaceDec));
        }

        override void visit(const StructDeclaration structDec)
        {
            addSymbol(new StructSymbol(structDec));
        }

        override void visit(const TemplateDeclaration templateDeclaration)
        {
            addSymbol(new TemplateSymbol(templateDeclaration));
        }

        override void visit(const StaticConstructor s)
        {
        }

        override void visit(const StaticDestructor s)
        {
        }

        override void visit(const SharedStaticConstructor s)
        {
        }

        override void visit(const SharedStaticDestructor s)
        {
        }

        override void visit(const Unittest u) {}

        override void visit(const UnionDeclaration unionDeclaration)
        {
            addSymbol(new UnionSymbol(unionDeclaration));
        }

        override void visit(const VariableDeclaration variableDeclaration)
        {
        }

    private:

        alias visit = ASTVisitor.visit;
    }

    protected override void doFetch()
    {
        auto mf = scoped!ModuleFetcher();
        mf.visit(_module);
    }

    private Module _module;
}

class PackageSymbol : ClassSymbol
{
    this()
    {
        super(null);
        _symbolType = SymbolType.PACKAGE;
    }
}

class EnumSymbol : DSymbol
{
    this(const EnumDeclaration decl)
    {
        _symbolType = SymbolType.ENUM;
        _decl = decl;
    }

    DSymbol[] _children;

    override DSymbol[] dotAccess()
    {
        fetch();
        return _children;
    }

    override DSymbol[] scopeAccess()
    {
        return [];
    }

    override void addSymbol(DSymbol symbol)
    {
        _children ~= symbol;
    }

    override void injectSymbol(DSymbol symbol)
    {
        return;
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }

    override string name() const
    {
        return _decl.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }

    private const EnumDeclaration _decl;
}


class VarSymbol : DSymbol
{
    this()
    {
        super(SymbolType.VAR);
    }

    DSymbol _type;

    override void addSymbol(DSymbol symbol)
    {
        return;
    }

    override void injectSymbol(DSymbol symbol)
    {
        return;
    }

    override DSymbol[] dotAccess()
    {
        fetch();
        return _type.dotAccess();
    }

    override DSymbol[] scopeAccess()
    {
        return [];
    }

    override DSymbol[] templateInstantiation(const Token[] tokens) { return []; }
    override DSymbol[] applyArguments(const Token[] tokens) { return []; }
}

class EnumVarSymbol : VarSymbol
{
    this(const EnumMember mem)
    {
        _mem = mem;
        _symbolType = SymbolType.ENUM_VAR;
    }

    override string name() const
    {
        return _mem.name.text;
    }
    override string type() const
    {
        return "";
    }

    override ubyte offset() const
    {
        return 0;
    }

    override void doFetch()
    {

    }


    const EnumMember _mem;
}

