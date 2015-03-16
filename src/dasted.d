module dasted;

import message_struct;
import dcd_bridge;
import outline;

import std.exception;
import std.socket;
import std.stdio;
import std.conv;

import msgpack;
import std.d.ast;
import std.d.parser;

import autocomplete;


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
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
    }

    void run(ushort port)
    {
        inbuffer.length = 1024;
        scope (exit)
        {
                socket.shutdown(SocketShutdown.BOTH);
                socket.close();
        }
        socket.bind(new InternetAddress("localhost", port));
        socket.listen(0);
        while (true)
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

private:

    void processRequest(T)(const T req)
    {
        auto rep = onMessage(req);
        sendReply(rep);
    }

    Reply!(MessageType.WRONG_TYPE) onMessage(T)(const T req)
    {
        throw new DastedException("unsupported request type (not implemented yet)");
    }

    Reply!(MessageType.COMPLETE) onMessage(const Request!(MessageType.COMPLETE) req)
    {
        auto dcdReq = toDcdRequest(req);
        auto resp = complete(dcdReq);
        return fromDcdResponse!(MessageType.COMPLETE)(resp);
    }

    Reply!(MessageType.FIND_DECLARATION) onMessage(const Request!(MessageType.FIND_DECLARATION) req)
    {
        auto dcdReq = toDcdRequest(req);
        auto resp = findDeclaration(dcdReq);
        return fromDcdResponse!(MessageType.FIND_DECLARATION)(resp);
    }

    Reply!(MessageType.ADD_IMPORT_PATHS) onMessage(const Request!(MessageType.ADD_IMPORT_PATHS) req)
    {
        addImportPaths(req.paths);
        return Reply!(MessageType.ADD_IMPORT_PATHS)();
    }

    Reply!(MessageType.GET_DOC) onMessage(const Request!(MessageType.GET_DOC) req)
    {
        auto dcdReq = toDcdRequest(req);
        auto resp = getDoc(dcdReq);
        return fromDcdResponse!(MessageType.GET_DOC)(resp);
    }

    Reply!(MessageType.OUTLINE) onMessage(const Request!(MessageType.OUTLINE) req)
    {
        return getOutline(req);
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

    void process(Socket s)
    {
        receive(s);
        enforce(inbuffer.length > uint.sizeof + ubyte.sizeof + ubyte.sizeof, "message is too small");
        ubyte vers = to!ubyte(inbuffer[uint.sizeof]);
        enforce(vers == PROTOCOL_VERSION, "unsupported protocol version " ~ to!string(vers));
        MessageType type = to!MessageType(inbuffer[uint.sizeof + vers.sizeof]);
        auto msg = unpack(inbuffer[(uint.sizeof + type.sizeof + ubyte.sizeof)..$]);
        final switch (type)
        {
            mixin(GenerateTypeSwitch!(MessageType));
        }
        send(s);
    }

    void sendReply(T)(const ref T rep)
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
        s.send((cast(ubyte*) &length)[0..length.sizeof]);
        s.send(header);
        s.send(outbuffer);
    }

    TcpSocket socket;
    ubyte[2] header;
    ubyte[] inbuffer;
    ubyte[] outbuffer;
    enum MAX_MESSAGE_SIZE = 32 * 1024 * 1024;
}
