module dasted;
import message_struct;
import dcd_bridge;

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

    void onMessage(T)(const T req)
    {
        throw new DastedException("unsupported request type (not implemented yet)");
    }

    void onMessage(const Request!(MessageType.COMPLETE) req)
    {
        auto dcdReq = toDcdRequest(req);
        auto resp = complete(dcdReq);
        auto rep = fromDcdResponse!(MessageType.COMPLETE)(resp);
        sendReply(rep);
    }

    void onMessage(const Request!(MessageType.FIND_DECLARATION) req)
    {
        auto dcdReq = toDcdRequest(req);
        auto resp = complete(dcdReq);
        auto rep = fromDcdResponse!(MessageType.FIND_DECLARATION)(resp);
        sendReply(rep);
    }

    void onMessage(const Request!(MessageType.ADD_IMPORT_PATHS) req)
    {
        addImportPaths(req.paths);
        Reply!(MessageType.ADD_IMPORT_PATHS) rep;
        sendReply(rep);
    }

    void onMessage(const Request!(MessageType.GET_DOC) req)
    {
        auto dcdReq = toDcdRequest(req);
        auto resp = getDoc(dcdReq);
        auto rep = fromDcdResponse!(MessageType.GET_DOC)(resp);
        sendReply(rep);
    }

    template GenerateTypeSwitch(T)
    {
        static string gen(string e)
        {
            return " onMessage(msg.as!(Request!(" ~ T.stringof ~ "." ~ e ~ "))());";
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
        auto pkg = unpack(inbuffer[uint.sizeof..$]);
        enforce(pkg.length == 2, "Unpacked length " ~ to!string(pkg.length));
        enforce(pkg.type == pkg.type.array, "Unpacked type " ~ to!string(pkg.type.array));
        auto valArr = pkg.via.array;
        enforce(valArr.length == 2, "Unpacked value length " ~ to!string(valArr.length));
        MessageType type = valArr[0].as!MessageType();
        auto msg = valArr[1];
        final switch (type)
        {
            mixin(GenerateTypeSwitch!(MessageType));
        }
        send(s);
    }

    void sendReply(T)(const ref T rep)
    {
        outbuffer = msgpack.pack(rep);
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
        uint length = cast(uint)outbuffer.length;
        s.send((cast(ubyte*) &length)[0..length.sizeof]);
        s.send(outbuffer);
    }

    TcpSocket socket;
    ubyte[] inbuffer;
    ubyte[] outbuffer;
    enum MAX_MESSAGE_SIZE = 32 * 1024 * 1024;
}
