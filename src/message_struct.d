module message_struct;

import messages;

enum ubyte PROTOCOL_VERSION = 1;

struct Location
{
    string filename;
    uint cursor;
}

alias CompletionKind SymbolType;

struct Symbol
{
    ubyte type;
    Location location;
    string name;
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
    GET_DOC,
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

struct Request(MessageType T : MessageType.GET_DOC)
{
    enum type = T;
    string src;
    uint cursor;
}

struct Reply(MessageType T)
{
    enum type = MessageType.WRONG_TYPE;
}

struct Reply(MessageType T : MessageType.COMPLETE)
{
    enum type = T;
    bool calltips;
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
    ubyte payload;
}

struct Reply(MessageType T : MessageType.GET_DOC)
{
    enum type = T;
    Symbol[] symbols;
}
