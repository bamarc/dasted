module evaluator;

import std.algorithm;
import std.file;
import std.range;

import dsymbols.common;
import logger;
import moduleparser;
import tokenutils;

import dparse.ast;

class AutoVariableEvaluator : TypeEvaluator
{
    this(const(Initializer) node, ISymbol s)
    {
        _symbol = s;
        auto visitor = new Visitor;
        node.accept(visitor);
        _impl = visitor.result;
    }

    override ISymbol[] evaluate()
    {
        debug trace("auto var evaluation ", _results is null, " ",_impl is null, " ",
            _symbol !is null ? debugString(_symbol) : "null");
        if (_results is null && _impl !is null)
        {
            _results = _impl.evaluate();
        }
        return _results;
    }

private:
    ISymbol _symbol;
    ISymbol[] _results;
    TypeEvaluator _impl;

    class Visitor : ASTVisitor
    {
        class UnaryEvaluator : TypeEvaluator
        {
            string token;
            TypeEvaluator prev;
            this(TypeEvaluator ev, string t)
            {
                token = t;
                prev = ev;
            }
            override ISymbol[] evaluate()
            {
                auto symb = _symbol;
                if (prev !is null)
                {
                    auto candidates = prev.evaluate();
                    if (candidates.empty())
                    {
                        return null;
                    }
                    debug trace("candidates = ", candidates.map!(a => debugString(a)));
                    symb = candidates.front();
                    auto res = candidates.front.dotAccess.filter!(a => a.name() == token).array;
                    debug trace("new candidates = ", res.map!(a => debugString(a)));
                    return res;
                }
                return findSymbol(symb, [token]);
            }
        }

        class NewExpressionEvaluator : TypeEvaluator
        {
            DType type;
            this(const(NewExpression) newExpr)
            {
                if (newExpr !is null)
                {
                    type = toDType(newExpr.type);
                }
            }
            override ISymbol[] evaluate()
            {
                return type.find(_symbol);
            }
        }
        override void visit(const UnaryExpression un)
        {
            debug trace("unary visit = ", un.identifierOrTemplateInstance is null ? null
                : txt(un.identifierOrTemplateInstance.identifier));
            if (un.newExpression !is null)
            {
                result = new NewExpressionEvaluator(un.newExpression);
                return;
            }
            un.accept(this);
            if (un.identifierOrTemplateInstance !is null)
            {
                if (un.identifierOrTemplateInstance.identifier.type == tok!"identifier")
                {
                    auto ev = new UnaryEvaluator(result,
                        txt(un.identifierOrTemplateInstance.identifier));
                    result = ev;
                }
            }
        }
        override void visit(const PrimaryExpression un)
        {
            debug trace("primary visit = ", un.identifierOrTemplateInstance is null ? null
                : txt(un.identifierOrTemplateInstance.identifier));
            un.accept(this);
            if (un.identifierOrTemplateInstance !is null)
            {
                if (un.identifierOrTemplateInstance.identifier.type == tok!"identifier")
                {
                    auto ev = new UnaryEvaluator(result,
                        txt(un.identifierOrTemplateInstance.identifier));
                    result = ev;
                }
            }
        }
        alias visit = ASTVisitor.visit;
        TypeEvaluator result;
        TypeEvaluator curr;
    }
}
