module message_struct;

import messages;

struct Location
{
    string filename;
    uint cursor;
}

alias CompletionKind SymbolType;

struct Symbol
{
    SymbolType type;
    string name;
    Location location;
    string[] qualifiers;
    string[] parameters;
    string[] templateParameters;
    string doc;
}

enum MessageType : ubyte
{
    WRONG_TYPE = 0,
    COMPLETE,
    FIND_DECLARATION,
}

struct Request
{
    MessageType type = type.WRONG_TYPE;
    string src;
    uint cursor;
}

struct Reply
{
    MessageType type = type.WRONG_TYPE;
    Symbol[] symbols;
}
