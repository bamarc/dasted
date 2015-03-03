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

struct Request(MessageType T)
{
    MessageType type = MessageType.WRONG_TYPE;
}

struct Request(MessageType T : MessageType.COMPLETE)
{
    MessageType type = T;
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.FIND_DECLARATION)
{
    enum type = T;
}

struct Reply(MessageType T)
{
    enum type = MessageType.WRONG_TYPE;
}

struct Reply(MessageType T : MessageType.COMPLETE)
{
    enum type = type.COMPLETE;
    Symbol[] symbols;
}
