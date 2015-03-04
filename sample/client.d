import std.stdio;
import std.socket;
import message_struct;
import msgpack;

int main()
{
    TcpSocket c = new TcpSocket;
    c.connect(new InternetAddress("localhost", 9168));
    Request!(MessageType.COMPLETE) req;
    req.src = "int foo(); f";
    req.cursor = 11;
    auto bytes = msgpack.pack(MessageType.COMPLETE, req);
    uint[] len = [cast(uint)bytes.length];
    writeln("Length: ", len);
//    c.send(len);
//    c.send(bytes);
    return 0;
}
