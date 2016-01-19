module modulevisitor;

import attributeutils;
import dsymbols;
import modulecache;
import symbolfactory;
import logger;

import std.algorithm;
import std.typecons;
import std.traits;
import std.range;
import std.exception;

alias VisibilityMode = BitFlags!Visibility;

enum VisibilityMode Hidden = VisibilityMode(Visibility.NONE);
enum VisibilityMode AllVisible =
    VisibilityMode(Visibility.PUBLIC, Visibility.PRIVATE,
                   Visibility.PROTECTED, Visibility.PACKAGE,
                   Visibility.INTERNAL);
enum ImportVisible = AllVisible & ~VisibilityMode(Visibility.INTERNAL)
                                & ~VisibilityMode(Visibility.PRIVATE);



class ModuleVisitor : ASTVisitor
{
public:
    this(SymbolFactory factory, VisibilityMode mode)
    {
        _symbolFactory = factory;
        _mode = mode;
    }

    void reset(const Module mod)
    {
        _moduleSymbol = _symbolFactory.create(mod);
        _symbol = _moduleSymbol;
        pushVisibility(Visibility.PUBLIC);
    }

    void visitModule(const Module mod)
    {
        debug trace("Start visiting");
        _state.moduleSymbol = _moduleSymbol;
        mod.accept(this);
        debug trace("Stop visiting");
    }

    inout(ModuleSymbol) moduleSymbol() inout
    {
        return _moduleSymbol;
    }

    // viz - default visibility for children
    mixin template VisitNode(T, Visibility viz, bool shouldStop = false)
    {
        override void visit(const(T) node)
        {
            debug trace("Visiting ", typeof(node).stringof);
            auto sym = _symbolFactory.create(node, _state);
            static if (isIterable!(typeof(sym)))
            {
                if (sym.empty() || sym.front() is null)
                {
                    return;
                }
            }
            auto attrViz = getVisibility(currentVisibility(), _state.attributes);
            if (!(_mode & attrViz))
            {
                return;
            }
            static if (isIterable!(typeof(sym)))
            {
                static assert(shouldStop,
                    "Should stop in case of multiple symbols generation: "
                    ~ typeof(sym).stringof);
                foreach (s; sym)
                {
                    s.visibility(attrViz);
                    s.parent(_symbol);
                }
                auto next_symbol = sym.front();
            }
            else
            {
                sym.parent(_symbol);
                auto next_symbol = sym;
            }
            if (next_symbol.hasScope())
            {
                _moduleSymbol.addScope(next_symbol);
            }
            debug trace("AST processes ", debugString(next_symbol));
            debug (print_ast) log(repeat(' ', ast_depth++), T.stringof);
            static if (!shouldStop)
            {
                if (viz == Visibility.INTERNAL && !(_mode & Visibility.INTERNAL))
                {
                    return;
                }
                pushVisibility(viz);
                scope(exit) popVisibility();
                auto tmp = _symbol;
                _symbol = next_symbol;
                node.accept(this);
                _symbol = tmp;
            }
            debug (print_ast) --ast_depth;
        }
    }

    mixin VisitNode!(ClassDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(StructDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(VariableDeclaration, Visibility.PUBLIC, true);
    mixin VisitNode!(FunctionDeclaration, Visibility.INTERNAL);
    mixin VisitNode!(UnionDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(ImportDeclaration, Visibility.PUBLIC, true);
    mixin VisitNode!(Unittest, Visibility.INTERNAL);
    override void visit(const Declaration decl)
    {
        _state.attributes ~= decl.attributes;
        scope(exit) _state.attributes = _state.attributes[0 .. $ - decl.attributes.length];
        decl.accept(this);
    }

private:
    alias visit = ASTVisitor.visit;

    Visibility currentVisibility() const
    {
        return _vizStack.back();
    }

    void pushVisibility(Visibility v)
    {
        _vizStack ~= v;
    }

    void popVisibility()
    {
        _vizStack.popBack();
    }

    debug(print_ast) int ast_depth = 0;
    ISymbol _symbol = null;
    ModuleSymbol _moduleSymbol = null;
    SymbolState _state;
    SymbolFactory _symbolFactory;
    Visibility[] _vizStack;
    VisibilityMode _mode;
}
