module dasted;
import message_struct;
import std.exception;
import std.outbuffer;
import std.socket;
import msgpack;
import std.d.ast;
import std.d.parser;


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
            auto client = socket.accept();
            scope (exit)
            {
                socket.shutdown(SocketShutdown.BOTH);
                socket.close();
            }
            client.blocking = true;
            process(client);
        }
    }

private:

    void onMessage(T)(const T req)
    {
        throw new DastedException("unsupported request type (not implemented yet)");
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
        enforce(pkg.length == 1);
        enforce(pkg.type == pkg.type.array);
        auto valArr = pkg.via.array;
        enforce(valArr.length == 2);
        MessageType type = valArr[0].as!MessageType();
        auto msg = valArr[1];
        pragma(msg, GenerateTypeSwitch!(MessageType));
        final switch (type)
        {
            mixin(GenerateTypeSwitch!(MessageType));
        }
    }

    void sendReply(T)(Socket s, const ref T rep)
    {
        outbuffer = msgpack.pack(rep);
        send(s);
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
                inbuffer.length = length;
            }
        } while (offset < length);
    }


    void send(Socket s)
    {
        enforce(outbuffer.length > uint.sizeof, "outbuffer is too small");
        uint length = cast(uint)outbuffer.length;
        s.send((cast(ubyte*) &length)[0..length.sizeof]);
        s.send(outbuffer);
    }

    TcpSocket socket;
    ubyte[] inbuffer;
    ubyte[] outbuffer;
    enum MAX_MESSAGE_SIZE = 32 * 1024 * 1024;
}
