module dastedserver;

import engine;
import messages;
import logger;

import std.exception;
import std.socket;
import std.stdio;
import std.conv;
import std.array;
import std.algorithm;

import msgpack;
import dparse.ast;
import dparse.parser;

import convert;

alias MT = messages.MessageType;

class DastedException : Exception
{
    @safe pure nothrow
    this(string s, string fn = __FILE__, size_t ln = __LINE__)
    {
        super(s, fn, ln);
    }
}

class Dasted
{
    this()
    {
        socket = new TcpSocket(AddressFamily.INET);
        socket.blocking = true;
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR,
                         true);
    }

    void toggleLogMsg(string regexp, bool enable)
    {
        logger.toggleLogMsg(regexp, enable);
    }

    void setLogLevel(string lv)
    {
        logger.setLogLevel(lv);
    }

    Engine engine(string project)
    {
        auto e = project in engines;
        if (e !is null)
        {
            return *e;
        }
        auto newEngine = new Engine;
        foreach (i; globalImportPaths)
        {
            newEngine.addImportPath(i);
        }
        engines[project] = newEngine;
        return newEngine;
    }

    void addGlobalImportPath(string path)
    {
        globalImportPaths ~= path;
    }

    void run(ushort port)
    {
        stdout.writeln("Running...");
        inbuffer.length = 1024;
        scope (exit)
        {
                socket.shutdown(SocketShutdown.BOTH);
                socket.close();
        }
        socket.bind(new InternetAddress("localhost", port));
        socket.listen(0);
        isRunning = true;
        while (isRunning)
        {
            try
            {
                auto client = socket.accept();
                scope (exit)
                {
                    client.shutdown(SocketShutdown.BOTH);
                    client.close();
                }
                client.blocking = true;
                process(client);
            }
            catch (Exception ex)
            {
                stderr.writeln("Exception: ", ex.msg);
            }
        }
    }

    ubyte[] runOn(ubyte[] inbuffer, MessageType type)
    {
        return process(inbuffer, type);
    }

private:

    void processRequest(T)(const T req)
    {
        debug trace("Request: ", req.type);
        typeof(onMessage(req)) rep;
        try
        {
            rep = onMessage(req);
        }
        catch (Exception ex)
        {
            error(ex.msg);
        }
        packReply(rep);
    }

    Reply!(MT.WRONG_TYPE) onMessage(T)(const T req)
    {
        throw new DastedException(
            "unsupported request type (not implemented yet)");
    }

    Reply!(MT.COMPLETE) onMessage(const Request!(MT.COMPLETE) req)
    {
        auto eng = engine(req.project);
        eng.setSource(req.src.filename, extractSources(req.src.text),
                      req.src.revision);
        return typeof(return)(false,
            map!(a => toMSymbol(a))(
                eng.complete(req.cursor)).array());
    }

    Reply!(MT.FIND_DECLARATION) onMessage(
        const Request!(MT.FIND_DECLARATION) req)
    {
        auto eng = engine(req.project);
        eng.setSource(req.src.filename, extractSources(req.src.text),
                      req.src.revision);
        return typeof(return)(toMSymbol(eng.findDeclaration(req.cursor)));
    }

    Reply!(MessageType.ADD_IMPORT_PATHS) onMessage(const Request!(MessageType.ADD_IMPORT_PATHS) req)
    {
        auto eng = engine(req.project);
        foreach (string path; req.paths)
        {
            eng.addImportPath(path);
        }
        return typeof(return).init;
    }

    Reply!(MessageType.GET_DOC) onMessage(const Request!(MessageType.GET_DOC) req)
    {
        return typeof(return).init;
    }

    Reply!(MessageType.OUTLINE) onMessage(const Request!(MessageType.OUTLINE) req)
    {
        auto eng = engine(req.project);
        eng.setSource(req.src.filename, extractSources(req.src.text),
                      req.src.revision);
        return typeof(return)(toMScope(eng.outline()));
    }

    Reply!(MessageType.SHUTDOWN) onMessage(const Request!(MessageType.SHUTDOWN) req)
    {
        isRunning = false;
        return Reply!(MessageType.SHUTDOWN)();
    }

    template GenerateTypeSwitch(T)
    {
        static string gen(string e)
        {
            return " processRequest(msg.as!(Request!(" ~ T.stringof ~ "." ~ e ~ "))());";
        }

        static string gen()
        {
            import std.traits;
            import std.conv;
            string res;
            foreach (e; EnumMembers!T) {
                res ~= "case " ~ T.stringof ~ "." ~ to!string(e) ~ ": " ~ gen(to!string(e)) ~ "break;\n";
            }
            return res;
        }
        enum GenerateTypeSwitch = gen();
    }

    ubyte[] process(ubyte[] buffer, MessageType type)
    {
        auto msg = unpack(buffer);
        debug(msg) trace(msg.toJSONValue().toString());
        final switch (type)
        {
            mixin(GenerateTypeSwitch!(MessageType));
        }
        return outbuffer;
    }

    void process(Socket s)
    {
        receive(s);

        enforce(inbuffer.length > uint.sizeof + ubyte.sizeof + ubyte.sizeof, "message is too small");
        ubyte vers = to!ubyte(inbuffer[uint.sizeof]);
        enforce(vers == PROTOCOL_VERSION, "unsupported protocol version " ~ to!string(vers));
        MessageType type = to!MessageType(inbuffer[uint.sizeof + vers.sizeof]);

        process(inbuffer[(uint.sizeof + type.sizeof + ubyte.sizeof)..$], type);
        send(s);
    }

    void packReply(T)(const ref T rep)
    {
        outbuffer = msgpack.pack(rep);
        header = [PROTOCOL_VERSION, rep.type];
    }

    void receive(Socket s)
    {
        uint length = uint.max;
        ptrdiff_t offset = 0;
        do {
            ptrdiff_t rc = s.receive(inbuffer[offset..$]);
            enforce(rc != Socket.ERROR, "socket error");
            enforce(rc != 0, "client closed connection");
            offset += rc;
            if (length == length.max && offset >= length.sizeof) {
                (cast(ubyte*) &length)[0..length.sizeof] = inbuffer[0..length.sizeof];
                enforce(length < MAX_MESSAGE_SIZE, "message buffer overflow");
                length += length.sizeof;
                inbuffer.length = length;
            }
        } while (offset < length);
    }


    void send(Socket s)
    {
        enforce(outbuffer.length, "outbuffer is empty");
        uint length = cast(uint)(outbuffer.length + header.sizeof);
        debug(msg) trace("Message body length = ", length);
        s.send((cast(ubyte*) &length)[0..length.sizeof]);
        s.send(header);
        s.send(outbuffer);
    }

    string extractSources(string s)
    {
        if (!s.startsWith("@"))
        {
            return s;
        }
        import std.file;
        auto fileName = s[1..$];
        if (exists(fileName) && isFile(fileName))
        {
            return readText(fileName);
        }
        return s;
    }

    TcpSocket socket;
    ubyte[2] header;
    ubyte[] inbuffer;
    ubyte[] outbuffer;
    bool isRunning = false;
    enum MAX_MESSAGE_SIZE = 32 * 1024 * 1024;

    uint revision;
    // TODO: a common cache for system directories
    Engine[string] engines;
    string[] globalImportPaths;

}
