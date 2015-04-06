module message_struct;

import messages;

enum ubyte PROTOCOL_VERSION = 3;

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
    string typeName;
    string[] qualifiers;
    string[] parameters;
    string[] templateParameters;
    string doc;
}

struct Scope
{
    Symbol master;
    Symbol[] symbols;
    Scope[] children;
}

enum MessageType : ubyte
{
    WRONG_TYPE = 0,
    COMPLETE,
    FIND_DECLARATION,
    ADD_IMPORT_PATHS,
    GET_DOC,
    OUTLINE,
    LOCAL_USAGE,
    USAGE,
    CLASS_HIERARCHY,
    SHUTDOWN,
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

struct Request(MessageType T : MessageType.OUTLINE)
{
    enum type = T;
    string src;
}

struct Request(MessageType T : MessageType.LOCAL_USAGE)
{
    enum type = T;
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.USAGE)
{
    enum type = T;
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.CLASS_HIERARCHY)
{
    enum type = T;
    string[] filePaths;
}

struct Request(MessageType T : MessageType.SHUTDOWN)
{
    enum type = T;
    bool payload;
}

// Replies

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

struct Reply(MessageType T : MessageType.OUTLINE)
{
    enum type = T;
    Scope global;
}

struct Reply(MessageType T : MessageType.LOCAL_USAGE)
{
    enum type = T;
    Symbol[] symbols;
}

struct Reply(MessageType T : MessageType.USAGE)
{
    enum type = T;
    Symbol[] symbols;
}

struct Reply(MessageType T : MessageType.CLASS_HIERARCHY)
{
    enum type = T;
    Symbol[] base;
    Symbol[] derived;
}

struct Reply(MessageType T : MessageType.SHUTDOWN)
{
    enum type = T;
    bool payload;
}
