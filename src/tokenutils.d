module tokenutils;

import dsymbols.common;

import dparse.ast;

import dparse.lexer;
import dparse.parser;

import logger;

import std.algorithm;
import std.array;
import std.typecons;


string txt(const(Token) t)
{
    return t.text.idup;
}

string tokToString(IdType t)
{
    return str(t);
}

string tokToString(const(Token) t)
{
    return t.type == tok!"identifier" ? txt(t) : tokToString(t.type);
}

Offset offset(Token t)
{
    return cast(Offset)t.index;
}

string[] txtChain(const IdentifierChain chain)
{
    return chain is null ? []
        : map!(a => txt(a))(chain.identifiers).array();
}

Offset offsetChain(const IdentifierChain chain)
{
    return chain is null || chain.identifiers.empty() ? BadOffset
        : offset(chain.identifiers.front());
}

string joinChain(string[] chain)
{
    return join(chain, '.');
}

ScopeBlock fromBlock(Block)(const Block bs)
    if (is(Block == BlockStatement) || is(Block == StructBody) || is(Block == EnumBody))
{
    return bs is null ? ScopeBlock()
        : ScopeBlock(cast(Offset)bs.startLocation,
        cast(Offset)bs.endLocation);
}

ScopeBlock fromFunctionBody(const FunctionBody fb)
{
    import std.typecons;
    Rebindable!(const(BlockStatement)) st;

    if (fb is null)
    {
        return ScopeBlock.init;
    }

    st = safeNull(fb).blockStatement.get;
    if (st.get is null)
    {
        st = safeNull(fb).bodyStatement.blockStatement.get;
    }
    return fromBlock(st.get);
}

enum ParenthesisType
{
    NONE = 0,
    ROUND = 1,
    SQUARE = 2,
    CURLY = 3,
}

Tuple!(ParenthesisType, bool) getParenthesisType(const(Token) t)
{
    switch (t.type)
    {
    case tok!"(": return tuple(ParenthesisType.ROUND, true);
    case tok!")": return tuple(ParenthesisType.ROUND, false);
    case tok!"[": return tuple(ParenthesisType.SQUARE, true);
    case tok!"]": return tuple(ParenthesisType.SQUARE, false);
    case tok!"{": return tuple(ParenthesisType.CURLY, true);
    case tok!"}": return tuple(ParenthesisType.CURLY, false);
    default: break;
    }
    return tuple(ParenthesisType.NONE, false);
}

Tuple!(const(Token)[], bool, int) getIdentifierChain(R)(R range, bool complete)
{
    bool calltip = false;
    int calltipIndex = 0;
    const(Token)[] res;
    if (range.back.type == tok!",")
    {
        if (!complete)
        {
            return typeof(return).init;
        }
        int parentheses = 0;
        while (!range.empty())
        {
            if (range.back.type != tok!";")
            {
                return typeof(return).init;
            }
            auto isParenthesis = getParenthesisType(range.back);

            if (isParenthesis[0] == ParenthesisType.ROUND)
            {
                if (!isParenthesis[1])
                {
                    ++parentheses;
                }
                else
                {
                    if (parentheses < 0)
                    {
                        calltip = true;
                        break;
                    }
                }
            }
            else if (range.back.type == tok!"," && parentheses == 0)
            {
                ++calltipIndex;
            }
            range.popBack();
        }
    }
    else if (range.back.type == tok!",")
    {
        calltip = true;
    }

    int[ParenthesisType.max + 1] parentheses;
    while (!range.empty)
    {
        auto isParenthesis = getParenthesisType(range.back);
        if (isParenthesis[0] != ParenthesisType.NONE)
        {
            if (!isParenthesis[1])
            {
                ++parentheses[isParenthesis[0]];
            }
            else
            {
                if (parentheses[isParenthesis[0]] > 0)
                {
                    --parentheses[isParenthesis[0]];
                }
                else
                {
                    break;
                }
            }
        }
        else if (parentheses[].all!(a => a == 0) && range.back.type != tok!"identifier"
                 && range.back.type != tok!"." && range.back.type != tok!"this")
        {
            break;
        }
        res ~= range.back();
        range.popBack();
    }
    return tuple(res, calltip, calltipIndex);
}

unittest
{
    import engine;
    Engine e = new Engine;
    string src1 = "int a; a.b.foo(a, b).";
    e.setSource("test", src1, 0);
    auto toks = e.activeTokens();
    auto res1 = getIdentifierChain(toks, true);
    assert(res1[0].map!(a => tokToString(a)).equal(
        [".", ")", "b", ",", "a", "(", "foo", ".", "b", ".", "a"]));

    string src2 = "Type t.a(p)";
    e.setSource("test", src2, 0);
    toks = e.activeTokens();
    auto res2 = getIdentifierChain(toks, true);
//    import std.stdio; writeln(res2[0].map!(a => tokToString(a)).array);
//    assert(res2[0].map!(a => tokToString(a)).equal(
//        [")", "p", "(", "a", ".", "t"]));
}

struct TokenStream
{
    private const(Token)[] _tokens;
    private Token _next;

    this(const(Token)[] tokens)
    {
        _tokens = tokens;
        next();
    }

    @property ref const(Token) curr() const
    {
        return _next;
    }

    bool next()
    {
        if (!hasNext())
        {
            return false;
        }
        _next = _tokens.back();
        _tokens.popBack();
        return true;
    }

    bool hasNext() const
    {
        return !_tokens.empty();
    }
}

DType toDType(const(Type2) type2)
{
    if (type2 is null)
    {
        return DType();
    }
    if (type2.builtinType != tok!"")
    {
        return DType(tokToString(type2.builtinType), true);
    }
    else if (type2.symbol !is null)
    {
        auto tmp = type2.symbol.identifierOrTemplateChain;
        if (tmp is null)
        {
            return DType();
        }
        auto chain = tmp.identifiersOrTemplateInstances;
        static SimpleDType asSimpleDType(const IdentifierOrTemplateInstance x)
        {
            if (x is null)
            {
                return typeof(return).init;
            }
            import logger;
            debug trace("Simple ", txt(x.identifier));
            if (x.templateInstance is null)
            {
                return SimpleDType(txt(x.identifier));
            }
            auto result = SimpleDType(txt(x.templateInstance.identifier));
            auto ta = x.templateInstance.templateArguments;
            if (ta is null)
            {
                return result;
            }
            if (ta.templateSingleArgument !is null)
            {
                result.templateArguments ~= DType(
                    [SimpleDType(txt(ta.templateSingleArgument.token))]);
            }
            else if (ta.templateArgumentList !is null)
            {
                result.templateArguments =
                    ta.templateArgumentList.items.filter!(a => a !is null)
                    .map!(a => toDType(a.type)).array();
            }
            return result;
        }
        return DType(chain.map!(a => asSimpleDType(a)).array());
    }
    else if (type2.type !is null)
    {
        return toDType(type2.type);
    }
    return DType();
}

DType toDType(const(Type) type)
{
    if (type is null)
    {
        return DType();
    }
    return toDType(type.type2);
}

string[] toIdentifierChain(const(UnaryExpression) unaryExpr)
{
    string[] tokens;
    import std.typecons : rebindable;
    auto u = rebindable(unaryExpr);
    while (u !is null)
    {
        if (u.identifierOrTemplateInstance !is null)
        {
            tokens = txt(u.identifierOrTemplateInstance.identifier) ~ tokens;
        }
        if (u.primaryExpression !is null
            && u.primaryExpression.identifierOrTemplateInstance !is null)
        {
            tokens = txt(u.primaryExpression.identifierOrTemplateInstance.identifier)
                ~ tokens;
        }
        u = u.unaryExpression;
    }
    return tokens;
}

auto debugStringUnsafe(T)(const(T) node)
    if (is(T : ASTNode))
{
    import msgpack;
    return node.pack!true().unpack().toJSONValue().toString();
}

auto debugTypes(T)(const(T) node, bool fancy = true)
    if (is(T : ASTNode))
{
    if (node is null)
    {
        return "null";
    }
    string res;
    final class ASTType : ASTVisitor
    {
        alias visit = ASTVisitor.visit;
        int depth = 0;
        mixin template impl(T)
        {
            override void visit(const(T) t)
            {
                if (fancy)
                {
                    import std.range;
                    res ~= "\n" ~ repeat("  ", depth).join ~ typeid(t).toString();
                    ++depth;
                }
                else
                {
                    res ~= typeid(t).toString();
                    res ~= ": [";
                }
                super.visit(t);
                if (fancy)
                {
                    --depth;
                }
                else
                {
                    res ~= "],";
                }
            }
        }
        mixin impl!(AddExpression);
        mixin impl!(AliasDeclaration);
        mixin impl!(AliasInitializer);
        mixin impl!(AliasThisDeclaration);
        mixin impl!(AlignAttribute);
        mixin impl!(AndAndExpression);
        mixin impl!(AndExpression);
        mixin impl!(AnonymousEnumDeclaration);
        mixin impl!(AnonymousEnumMember);
        mixin impl!(ArgumentList);
        mixin impl!(Arguments);
        mixin impl!(ArrayInitializer);
        mixin impl!(ArrayLiteral);
        mixin impl!(ArrayMemberInitialization);
        mixin impl!(AsmAddExp);
        mixin impl!(AsmAndExp);
        mixin impl!(AsmBrExp);
        mixin impl!(AsmEqualExp);
        mixin impl!(AsmExp);
        mixin impl!(AsmInstruction);
        mixin impl!(AsmLogAndExp);
        mixin impl!(AsmLogOrExp);
        mixin impl!(AsmMulExp);
        mixin impl!(AsmOrExp);
        mixin impl!(AsmPrimaryExp);
        mixin impl!(AsmRelExp);
        mixin impl!(AsmShiftExp);
        mixin impl!(AsmStatement);
        mixin impl!(AsmTypePrefix);
        mixin impl!(AsmUnaExp);
        mixin impl!(AsmXorExp);
        mixin impl!(AssertExpression);
        mixin impl!(AssignExpression);
        mixin impl!(AssocArrayLiteral);
        mixin impl!(AtAttribute);
        mixin impl!(Attribute);
        mixin impl!(AttributeDeclaration);
        mixin impl!(AutoDeclaration);
        mixin impl!(BlockStatement);
        mixin impl!(BodyStatement);
        mixin impl!(BreakStatement);
        mixin impl!(BaseClass);
        mixin impl!(BaseClassList);
        mixin impl!(CaseRangeStatement);
        mixin impl!(CaseStatement);
        mixin impl!(CastExpression);
        mixin impl!(CastQualifier);
        mixin impl!(Catch);
        mixin impl!(Catches);
        mixin impl!(ClassDeclaration);
        mixin impl!(CmpExpression);
        mixin impl!(CompileCondition);
        mixin impl!(ConditionalDeclaration);
        mixin impl!(ConditionalStatement);
        mixin impl!(Constraint);
        mixin impl!(Constructor);
        mixin impl!(ContinueStatement);
        mixin impl!(DebugCondition);
        mixin impl!(DebugSpecification);
        mixin impl!(Declaration);
        mixin impl!(DeclarationOrStatement);
        mixin impl!(DeclarationsAndStatements);
        mixin impl!(Declarator);
        mixin impl!(DefaultStatement);
        mixin impl!(DeleteExpression);
        mixin impl!(DeleteStatement);
        mixin impl!(Deprecated);
        mixin impl!(Destructor);
        mixin impl!(DoStatement);
        mixin impl!(EnumBody);
        mixin impl!(EnumDeclaration);
        mixin impl!(EnumMember);
        mixin impl!(EponymousTemplateDeclaration);
        mixin impl!(EqualExpression);
        mixin impl!(Expression);
        mixin impl!(ExpressionStatement);
        mixin impl!(FinalSwitchStatement);
        mixin impl!(Finally);
        mixin impl!(ForStatement);
        mixin impl!(ForeachStatement);
        mixin impl!(ForeachType);
        mixin impl!(ForeachTypeList);
        mixin impl!(FunctionAttribute);
        mixin impl!(FunctionBody);
        mixin impl!(FunctionCallExpression);
        mixin impl!(FunctionDeclaration);
        mixin impl!(FunctionLiteralExpression);
        mixin impl!(GotoStatement);
        mixin impl!(IdentifierChain);
        mixin impl!(IdentifierList);
        mixin impl!(IdentifierOrTemplateChain);
        mixin impl!(IdentifierOrTemplateInstance);
        mixin impl!(IdentityExpression);
        mixin impl!(IfStatement);
        mixin impl!(ImportBind);
        mixin impl!(ImportBindings);
        mixin impl!(ImportDeclaration);
        mixin impl!(ImportExpression);
        mixin impl!(IndexExpression);
        mixin impl!(InExpression);
        mixin impl!(InStatement);
        mixin impl!(Initialize);
        mixin impl!(Initializer);
        mixin impl!(InterfaceDeclaration);
        mixin impl!(Invariant);
        mixin impl!(IsExpression);
        mixin impl!(KeyValuePair);
        mixin impl!(KeyValuePairs);
        mixin impl!(LabeledStatement);
        mixin impl!(LastCatch);
        mixin impl!(LinkageAttribute);
        mixin impl!(MemberFunctionAttribute);
        mixin impl!(MixinDeclaration);
        mixin impl!(MixinExpression);
        mixin impl!(MixinTemplateDeclaration);
        mixin impl!(MixinTemplateName);
        mixin impl!(Module);
        mixin impl!(ModuleDeclaration);
        mixin impl!(MulExpression);
        mixin impl!(NewAnonClassExpression);
        mixin impl!(NewExpression);
        mixin impl!(NonVoidInitializer);
        mixin impl!(Operands);
        mixin impl!(OrExpression);
        mixin impl!(OrOrExpression);
        mixin impl!(OutStatement);
        mixin impl!(dparse.ast.Parameter);
        mixin impl!(Parameters);
        mixin impl!(Postblit);
        mixin impl!(PowExpression);
        mixin impl!(PragmaDeclaration);
        mixin impl!(PragmaExpression);
        mixin impl!(PrimaryExpression);
        mixin impl!(Register);
        mixin impl!(RelExpression);
        mixin impl!(ReturnStatement);
        mixin impl!(ScopeGuardStatement);
        mixin impl!(SharedStaticConstructor);
        mixin impl!(SharedStaticDestructor);
        mixin impl!(ShiftExpression);
        mixin impl!(SingleImport);
        mixin impl!(Index);
        mixin impl!(Statement);
        mixin impl!(StatementNoCaseNoDefault);
        mixin impl!(StaticAssertDeclaration);
        mixin impl!(StaticAssertStatement);
        mixin impl!(StaticConstructor);
        mixin impl!(StaticDestructor);
        mixin impl!(StaticIfCondition);
        mixin impl!(StorageClass);
        mixin impl!(StructBody);
        mixin impl!(StructDeclaration);
        mixin impl!(StructInitializer);
        mixin impl!(StructMemberInitializer);
        mixin impl!(StructMemberInitializers);
        mixin impl!(SwitchStatement);
        mixin impl!(Symbol);
        mixin impl!(SynchronizedStatement);
        mixin impl!(TemplateAliasParameter);
        mixin impl!(TemplateArgument);
        mixin impl!(TemplateArgumentList);
        mixin impl!(TemplateArguments);
        mixin impl!(TemplateDeclaration);
        mixin impl!(TemplateInstance);
        mixin impl!(TemplateMixinExpression);
        mixin impl!(TemplateParameter);
        mixin impl!(TemplateParameterList);
        mixin impl!(TemplateParameters);
        mixin impl!(TemplateSingleArgument);
        mixin impl!(TemplateThisParameter);
        mixin impl!(TemplateTupleParameter);
        mixin impl!(TemplateTypeParameter);
        mixin impl!(TemplateValueParameter);
        mixin impl!(TemplateValueParameterDefault);
        mixin impl!(TernaryExpression);
        mixin impl!(ThrowStatement);
        // mixin impl!(Token);
        mixin impl!(TraitsExpression);
        mixin impl!(TryStatement);
        mixin impl!(Type);
        mixin impl!(Type2);
        mixin impl!(TypeSpecialization);
        mixin impl!(TypeSuffix);
        mixin impl!(TypeidExpression);
        mixin impl!(TypeofExpression);
        mixin impl!(UnaryExpression);
        mixin impl!(UnionDeclaration);
        mixin impl!(Unittest);
        mixin impl!(VariableDeclaration);
        mixin impl!(Vector);
        mixin impl!(VersionCondition);
        mixin impl!(VersionSpecification);
        mixin impl!(WhileStatement);
        mixin impl!(WithStatement);
        mixin impl!(XorExpression);
        override void visit(const Token n)
        {
            if (fancy)
            {
                import std.range;
                res ~= "\n" ~ repeat("  ", depth).join ~ "tok = " ~ txt(n);
            }
            else
            {
                res ~= "tok = " ~ txt(n) ~ ",";
            }
        }
    }
    auto t = new ASTType;
    t.visit(node);
    return res;
}
