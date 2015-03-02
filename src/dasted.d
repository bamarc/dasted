module dasted;
import message_struct;
import std.exception;
import std.outbuffer;
import std.socket;
import msgpack;
import std.d.ast;
import std.d.parser;

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
            auto req = receiveRequest(client);
            auto rep = onRequest(req);
            sendReply(client, rep);
        }
    }

private:

    Request receiveRequest(Socket s)
    {
        receive(s);
        Request req;
        msgpack.unpack(inbuffer[uint.sizeof..$], req);
        return req;
    }

    void sendReply(Socket s, Reply rep)
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

    Reply onRequest(Request req)
    {
        final switch (req.type)
        {
            case req.type.WRONG_TYPE: return Reply();
            case req.type.COMPLETE: return onComplete(req);
            case req.type.FIND_DECLARATION: return onFindDeclaration(req);
        }
    }
    Reply onComplete(Request req)
    {
        return Reply();
    }
    Reply onFindDeclaration(Request req)
    {
        return Reply();
    }

    TcpSocket socket;
    ubyte[] inbuffer;
    ubyte[] outbuffer;
    enum MAX_MESSAGE_SIZE = 32 * 1024 * 1024;
}
