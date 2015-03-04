module dcd_bridge;

import std.conv;

import message_struct;
import autocomplete;
import messages;


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
    return res;
}
