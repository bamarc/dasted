module dcd_bridge;

import std.conv;
import std.typecons;
import std.array;
import std.algorithm;
import std.range;

import message_struct;
import autocomplete;
import messages;
import modulecache;
import std.allocator;
import memory.allocators;
import std.d.lexer;
import conversion.astconverter;
import string_interning;

import actypes;


void addImportPaths(const string[] paths)
{
    string[] p = paths.dup;
    ModuleCache.addImportPaths(p);
}


AutocompleteRequest toDcdRequest(const ref Request!(MessageType.COMPLETE) req)
{
    AutocompleteRequest res;
    res.kind = RequestKind.autocomplete;
    res.cursorPosition = req.cursor;
    res.sourceCode = cast(ubyte[])(req.src);
    return res;
}

AutocompleteRequest toDcdRequest(const ref Request!(MessageType.FIND_DECLARATION) req)
{
    AutocompleteRequest res;
    res.kind = RequestKind.symbolLocation;
    res.cursorPosition = req.cursor;
    res.sourceCode = cast(ubyte[])(req.src);
    return res;
}

AutocompleteRequest toDcdRequest(const ref Request!(MessageType.GET_DOC) req)
{
    AutocompleteRequest res;
    res.kind = RequestKind.doc;
    res.cursorPosition = req.cursor;
    res.sourceCode = cast(ubyte[])(req.src);
    return res;
}

Reply!T fromDcdResponse(MessageType T)(const ref AutocompleteResponse);

Reply!T fromDcdResponse(MessageType T : MessageType.COMPLETE)(const ref AutocompleteResponse resp)
{
    Reply!T res;
    foreach (i; 0..resp.completions.length)
    {
        Symbol s;
        s.name = resp.completions[i];
        if (resp.completionType == CompletionType.identifiers)
        {
            s.type = to!CompletionKind(resp.completionKinds[i]);
        }
        res.symbols ~= s;
    }
    res.calltips = resp.completionType == CompletionType.calltips;
    return res;
}

Reply!T fromDcdResponse(MessageType T : MessageType.FIND_DECLARATION)(const ref AutocompleteResponse response)
{
    Reply!T res;
    res.symbol.location.filename = response.symbolFilePath;
    res.symbol.location.cursor = to!(typeof(res.symbol.location.cursor))(response.symbolLocation);
    return res;
}

Reply!T fromDcdResponse(MessageType T : MessageType.GET_DOC)(const ref AutocompleteResponse response)
{
    Reply!T res;
    foreach (i; 0..response.docComments.length)
    {
        Symbol s;
        s.doc = response.docComments[i];
        res.symbols ~= s;
    }
    return res;
}

private enum TYPE_IDENT_AND_LITERAL_CASES = q{
    case tok!"int":
    case tok!"uint":
    case tok!"long":
    case tok!"ulong":
    case tok!"char":
    case tok!"wchar":
    case tok!"dchar":
    case tok!"bool":
    case tok!"byte":
    case tok!"ubyte":
    case tok!"short":
    case tok!"ushort":
    case tok!"cent":
    case tok!"ucent":
    case tok!"float":
    case tok!"ifloat":
    case tok!"cfloat":
    case tok!"idouble":
    case tok!"cdouble":
    case tok!"double":
    case tok!"real":
    case tok!"ireal":
    case tok!"creal":
    case tok!"this":
    case tok!"super":
    case tok!"identifier":
    case tok!"stringLiteral":
    case tok!"wstringLiteral":
    case tok!"dstringLiteral":
};

T getExpression(T)(T beforeTokens)
{
    enum EXPRESSION_LOOP_BREAK = q{
        if (i + 1 < beforeTokens.length) switch (beforeTokens[i + 1].type)
        {
            mixin (TYPE_IDENT_AND_LITERAL_CASES);
            i++;
            break expressionLoop;
            default:
            break;
        }
    };

    if (beforeTokens.length == 0)
    return beforeTokens[0 .. 0];
    size_t i = beforeTokens.length - 1;
    size_t sliceEnd = beforeTokens.length;
    IdType open;
    IdType close;
    uint skipCount = 0;

    expressionLoop: while (true)
    {
        switch (beforeTokens[i].type)
        {
            case tok!"import":
            break expressionLoop;
            mixin (TYPE_IDENT_AND_LITERAL_CASES);
            mixin (EXPRESSION_LOOP_BREAK);
            if (i > 1 && beforeTokens[i - 1] == tok!"!"
                && beforeTokens[i - 2] == tok!"identifier")
            {
                sliceEnd -= 2;
                i--;
            }
            break;
            case tok!".":
            break;
            case tok!")":
            open = tok!")";
            close = tok!"(";
            goto skip;
            case tok!"]":
            open = tok!"]";
            close = tok!"[";
            skip:
            mixin (EXPRESSION_LOOP_BREAK);
            auto bookmark = i;
            int depth = 1;
            do
            {
                if (depth == 0 || i == 0)
                break;
                else
                    i--;
                if (beforeTokens[i].type == open)
                depth++;
                else if (beforeTokens[i].type == close)
                depth--;
            } while (true);

            skipCount++;

            // check the current token after skipping parens to the left.
            // if it's a loop keyword, pretend we never skipped the parens.
            if (i > 0) switch (beforeTokens[i - 1].type)
            {
                case tok!"scope":
                case tok!"if":
                case tok!"while":
                case tok!"for":
                case tok!"foreach":
                case tok!"foreach_reverse":
                case tok!"do":
                case tok!"cast":
                case tok!"catch":
                i = bookmark + 1;
                break expressionLoop;
                case tok!"!":
                if (skipCount == 1)
                {
                    sliceEnd = i - 1;
                    i -= 2;
                }
                break expressionLoop;
                default:
                break;
            }
            break;
            default:
            i++;
            break expressionLoop;
        }
        if (i == 0)
        break;
        else
            i--;
    }
    return beforeTokens[i .. sliceEnd];
}

istring stringToken()(auto ref const Token a)
{
        return internString(a.text is null ? str(a.type) : a.text);
}


ACSymbol* getDeclarationByTokenChain(T)(actypes.Scope* completionScope, T tokens, size_t cursorPosition)
{
    // Find the symbol corresponding to the beginning of the chain
    ACSymbol* symbol;
    ACSymbol*[] symbols;
    return symbol;
}

ACSymbol* getDeclaration(ubyte[] src, size_t pos)
{
    auto allocator = scoped!(CAllocatorImpl!(BlockAllocator!(1024 * 16)))();
    auto cache = StringCache(StringCache.defaultBucketCount);
    LexerConfig config;
    config.fileName = "";
    auto tokenArray = getTokensForParser(src, config, &cache);
    auto beforeTokens = assumeSorted(tokenArray).lowerBound(pos);
    auto completionScope = generateAutocompleteTrees(tokenArray, allocator);
    scope(exit) typeid(actypes.Scope).destroy(completionScope);
    auto expression = getExpression(beforeTokens);
    return getDeclarationByTokenChain(completionScope, expression, pos);
}
