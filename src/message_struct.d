module message_struct;

enum ubyte PROTOCOL_VERSION = 3;

struct Location
{
    string filename;
    uint cursor;
}

enum SymbolType : ubyte
{
     /// Invalid completion kind. This is used internally and will never
     /// be returned in a completion response.
     dummy = '?',

     /// Import symbol. This is used internally and will never
     /// be returned in a completion response.
     importSymbol = '*',

     /// With symbol. This is used internally and will never
     /// be returned in a completion response.
     withSymbol = 'w',

     /// class names
     className = 'c',

     /// interface names
     interfaceName = 'i',

     /// structure names
     structName = 's',

     /// union name
     unionName = 'u',

     /// variable name
     variableName = 'v',

     /// member variable
     memberVariableName = 'm',

     /// keyword, built-in version, scope statement
     keyword = 'k',

     /// function or method
     functionName = 'f',

     /// enum name
     enumName = 'g',

     /// enum member
     enumMember = 'e',

     /// package name
     packageName = 'P',

     /// module name
     moduleName = 'M',

     /// array
     array = 'a',

     /// associative array
     assocArray = 'A',

     /// alias name
     aliasName = 'l',

     /// template name
     templateName = 't',

     /// mixin template name
     mixinTemplateName = 'T',

 }

struct MSymbol
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
