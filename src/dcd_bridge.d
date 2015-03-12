module dcd_bridge;

import std.conv;

import message_struct;
import autocomplete;
import messages;
import modulecache;


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
