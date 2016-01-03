module modulevisitor;

import attributeutils;
import dsymbols;
import modulecache;
import symbolfactory;
import completionfilter;
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
enum OutlineVisible = AllVisible & ~VisibilityMode(Visibility.INTERNAL);



class ModuleVisitor : ASTVisitor
{
public:
    this(SymbolFactory factory, VisibilityMode mode)
    {
        _symbolFactory = factory;
        _mode = mode;
    }

    void visitModule(const Module mod)
    {
        _moduleSymbol = _symbolFactory.create(mod);
        _symbol = _moduleSymbol;
        mod.accept(this);
    }

    inout(ModuleSymbol) moduleSymbol() inout
    {
        return _moduleSymbol;
    }

    mixin template VisitNode(T, Visibility viz, bool shouldStop = false)
    {
        override void visit(const(T) node)
        {
            auto sym = _symbolFactory.create(node, _state);
            static if (isIterable!(typeof(sym)))
            {
                if (sym.empty() || sym.front() is null)
                {
                    return;
                }
            }
            auto attrViz = getVisibility(viz, _state.attributes);
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
            debug (print_ast) log(repeat(' ', ast_depth++), T.stringof);
            static if (!shouldStop)
            {

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
        AttributeStackGuard(&(_state.attributes), decl.attributes);
        decl.accept(this);
    }

private:
    private alias visit = ASTVisitor.visit;

    debug(print_ast) int ast_depth = 0;
    private ISymbol _symbol = null;
    private ModuleSymbol _moduleSymbol = null;
    private SymbolState _state;
    private SymbolFactory _symbolFactory;
    private VisibilityMode _mode;
}
