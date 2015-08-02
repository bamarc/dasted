import std.stdio;
import std.getopt;
import message_struct : PROTOCOL_VERSION;

import dastedserver;

int main(string[] args)
{
    ushort port = 11344;
    bool printVersion;

    getopt(args,
        "port|p", &port,
        "version", &printVersion);

    if (printVersion)
    {
        writeln(PROTOCOL_VERSION);
        return 0;
    }

    if (port <= 0)
    {
        writeln("Invalid port number");
        return 1;
    }

    Dasted d = new Dasted;
    d.run(port);
    return 0;
}
