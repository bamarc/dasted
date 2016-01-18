module messages;

enum ubyte PROTOCOL_VERSION = 4;

struct Location
{
    string filename;
    uint cursor;
}

struct Sources
{
    string filename;
    uint revision;
    string text;
}

enum SymbolType : ubyte
{
    UNKNOWN = 0,
    CLASS = 1,
    INTERFACE = 2,
    STRUCT = 3,
    UNION = 4,
    VARIABLE = 5,
    MEMBER = 6,
    KEYWORD = 7,
    FUNCTION = 8,
    ENUM = 9,
    ENUM_VARIABLE = 10,
    PACKAGE = 11,
    MODULE = 12,
    ARRAY = 13,
    ASSOCIATIVE_ARRAY = 14,
    ALIAS = 15,
    TEMPLATE = 16,
    MIXIN_TEMPLATE = 17,
}

struct MSymbol
{
    SymbolType type;
    Location location;
    string name;
    string typeName;
    string[] qualifiers;
    string[] parameters;
    string[] templateParameters;
    string doc;
}

struct MScope
{
    MSymbol symbol;
    MScope[] children;
}

enum MessageType : ubyte
{
    WRONG_TYPE = 0,
    COMPLETE = 1,
    FIND_DECLARATION = 2,
    ADD_IMPORT_PATHS = 3,
    GET_DOC = 4,
    OUTLINE = 5,
    LOCAL_USAGE = 6,
    USAGE = 7,
    CLASS_HIERARCHY = 8,
    SHUTDOWN = 9,
    ERROR = 10,
}

// Requests

struct Request(MessageType T)
{
    MessageType type = MessageType.WRONG_TYPE;
}

struct Request(MessageType T : MessageType.COMPLETE)
{
    enum type = T;
    string project;
    Sources src;
    uint cursor;
}

struct Request(MessageType T : MessageType.FIND_DECLARATION)
{
    enum type = T;
    string project;
    Sources src;
    uint cursor;
}

struct Request(MessageType T : MessageType.ADD_IMPORT_PATHS)
{
    enum type = T;
    string project;
    string[] paths;
}

struct Request(MessageType T : MessageType.GET_DOC)
{
    enum type = T;
    string project;
    Sources src;
    uint cursor;
}

struct Request(MessageType T : MessageType.OUTLINE)
{
    enum type = T;
    string project;
    Sources src;
}

struct Request(MessageType T : MessageType.LOCAL_USAGE)
{
    enum type = T;
    string project;
    Sources src;
    uint cursor;
}

struct Request(MessageType T : MessageType.USAGE)
{
    enum type = T;
    string project;
    Sources src;
    uint cursor;
}

struct Request(MessageType T : MessageType.CLASS_HIERARCHY)
{
    enum type = T;
    string project;
    string[] filePaths;
}

struct Request(MessageType T : MessageType.SHUTDOWN)
{
    enum type = T;
    string project;
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
    MSymbol[] symbols;
}

struct Reply(MessageType T : MessageType.FIND_DECLARATION)
{
    enum type = T;
    MSymbol symbol;
}

struct Reply(MessageType T : MessageType.ADD_IMPORT_PATHS)
{
    enum type = T;
    ubyte payload;
}

struct Reply(MessageType T : MessageType.GET_DOC)
{
    enum type = T;
    MSymbol[] symbols;
}

struct Reply(MessageType T : MessageType.OUTLINE)
{
    enum type = T;
    MScope global;
}

struct Reply(MessageType T : MessageType.LOCAL_USAGE)
{
    enum type = T;
    MSymbol[] symbols;
}

struct Reply(MessageType T : MessageType.USAGE)
{
    enum type = T;
    MSymbol[] symbols;
}

struct Reply(MessageType T : MessageType.CLASS_HIERARCHY)
{
    enum type = T;
    MSymbol[] base;
    MSymbol[] derived;
}

struct Reply(MessageType T : MessageType.SHUTDOWN)
{
    enum type = T;
    bool payload;
}

struct Reply(MessageType T : MessageType.ERROR)
{
    enum type = T;
    string description;
}
