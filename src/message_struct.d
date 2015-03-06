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
    ubyte type;
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
    ADD_IMPORT_PATHS,
}

struct Request(MessageType T)
{
    MessageType type = MessageType.WRONG_TYPE;
}

struct Request(MessageType T : MessageType.COMPLETE)
{
    enum type = T;
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.FIND_DECLARATION)
{
    enum type = T;
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.ADD_IMPORT_PATHS)
{
    enum type = T;
    string[] paths;
}

struct Reply(MessageType T)
{
    enum type = MessageType.WRONG_TYPE;
}

struct Reply(MessageType T : MessageType.COMPLETE)
{
    enum type = T;
    Symbol[] symbols;
}

struct Reply(MessageType T : MessageType.FIND_DECLARATION)
{
    enum type = T;
    Symbol symbol;
}

struct Reply(MessageType T : MessageType.ADD_IMPORT_PATHS)
{
    enum type = T;
}
