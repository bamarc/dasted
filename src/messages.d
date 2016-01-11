module messages;

enum ubyte PROTOCOL_VERSION = 4;

struct Location
{
    string filename;
    uint cursor;
}

enum SymbolType : ubyte
{
    UNKNOWN = 0,
    CLASS,
    INTERFACE,
    STRUCT,
    UNION,
    VARIABLE,
    MEMBER,
    KEYWORD,
    FUNCTION,
    ENUM,
    ENUM_VARIABLE,
    PACKAGE,
    MODULE,
    ARRAY,
    ASSOCIATIVE_ARRAY,
    ALIAS,
    TEMPLATE,
    MIXIN_TEMPLATE,
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
    MSymbol master;
    MSymbol[] symbols;
    MScope[] children;
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
    ERROR,
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
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.FIND_DECLARATION)
{
    enum type = T;
    string project;
    string src;
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
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.OUTLINE)
{
    enum type = T;
    string project;
    string src;
}

struct Request(MessageType T : MessageType.LOCAL_USAGE)
{
    enum type = T;
    string project;
    string src;
    uint cursor;
}

struct Request(MessageType T : MessageType.USAGE)
{
    enum type = T;
    string project;
    string src;
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
