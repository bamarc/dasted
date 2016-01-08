import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.range;
import messages : PROTOCOL_VERSION;

import dastedserver;

int main(string[] args)
{
    ushort port = 11344;
    bool printVersion;
    string dmdconf;

    getopt(args,
        "port|p", &port,
        "version", &printVersion,
        "dmdconf", &dmdconf);

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

    if (!dmdconf.empty() && exists(dmdconf) && isFile(dmdconf))
    {
        import std.regex, std.conv;
        auto r = regex("-I([^ ]*)");
        auto f = File(dmdconf);
        foreach (line; f.byLine)
        {
            foreach (m; matchAll(line, r))
            {
                d.addImportPath(to!string(m.captures[1]));
            }
        }
    }

    d.run(port);
    return 0;
}
