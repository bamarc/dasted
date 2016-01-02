module engine;

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

enum Hidden = VisibilityMode.init;
enum AllVisible = ~(Hidden);

struct SymbolState
{
    AttributeList attributes;
}

class ModuleVisitor(F) : ASTVisitor
{
    debug(print_ast) int ast_depth = 0;

    mixin template VisitNode(T, Visibility viz, bool shouldStop = false)
    {
        override void visit(const(T) node)
        {
            auto sym = _symbolFactory.create(node, _state);
            if (sym.empty() || sym.front() is null)
            {
                return;
            }
            auto attrViz = getVisibility(viz, attrs);
            if (!(_mode & attrViz))
            {
                return;
            }
            foreach (s; sym)
            {
                s.visibility(attrViz);
                s.parent(_symbol);
            }
            enforce(shouldStop || sym.length == 1);
            debug (print_ast) log(repeat(' ', ast_depth++), T.stringof);
            static if (!shouldStop)
            {
                auto tmp = _symbol;
                _symbol = sym.front();
                node.accept(this);
                _symbol = tmp;
            }
            debug (print_ast) --ast_depth;
        }
    }

    this(SymbolFactory factory, const Module mod, ASTMode mode)
    {
        _moduleSymbol = symbolFactory.create(mod, _state.attributes);
        _symbol = _moduleSymbol;
        _symbolFactory = new Factory;
        _mode = mode;
        mod.accept(this);
    }

    private DSymbol _symbol = null;
    private ModuleSymbol _moduleSymbol = null;

    mixin VisitNode!(ClassDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(StructDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(VariableDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(FunctionDeclaration, Visibility.INTERNAL);
    mixin VisitNode!(UnionDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(ImportDeclaration, Visibility.PUBLIC);
    mixin VisitNode!(Unittest, Visibility.INTERNAL);

    override void visit(const Declaration decl)
    {
        AttributeStackGuard(&(_state.attributes), decl.attibutes);
        decl.accept(this);
    }

    private alias visit = ASTVisitor.visit;
    private SymbolState _state;
    private SymbolFactory _symbolFactory;
    private ASTMode _mode;
}
