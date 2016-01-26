import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.range;
import messages;

import dastedserver;

int main(string[] args)
{
    ushort port = 11344;
    bool printVersion;
    string dmdconf;
    bool daemon;
    string[] disableMsg;
    string[] enableMsg;
    string logLevel;
    bool errorsAsReplies;

    getopt(args,
        "d|daemon", &daemon,
        "port|p", &port,
        "version", &printVersion,
        "dmdconf", &dmdconf,
        "disable_msg", &disableMsg,
        "enable_msg", &enableMsg,
        "errors_as_replies", &errorsAsReplies,
        "log_level", &logLevel);

    if (printVersion)
    {
        writeln(PROTOCOL_VERSION);
        return 0;
    }

    if (daemon && port <= 0)
    {
        writeln("Invalid port number");
        return 1;
    }

    auto d = new Dasted;
    d.

    d.setLogLevel(logLevel);

    foreach (i; disableMsg)
    {
        d.toggleLogMsg(i, false);
    }

    foreach (i; enableMsg)
    {
        d.toggleLogMsg(i, true);
    }

    if (!dmdconf.empty() && exists(dmdconf) && isFile(dmdconf))
    {
        import std.regex, std.conv;
        auto r = regex("-I([^ ]*)");
        auto f = File(dmdconf);
        foreach (line; f.byLine)
        {
            foreach (m; matchAll(line, r))
            {
                d.addGlobalImportPath(to!string(m.captures[1]));
            }
        }
    }

    if (daemon)
    {
        d.run(port);
    }
    else
    {
        import std.conv;
        import std.json;
        import msgpack;
        auto inputJsonString = stdin.byLine.join("\n");
        auto inputJson = parseJSON(inputJsonString);
        foreach (j; inputJson.array)
        {
            auto type = j["type"].integer();
            auto msg = msgpack.fromJSONValue(j["msg"]).pack();
            auto rep = d.runOn(msg, to!MessageType(type));
            writeln(rep.unpack().toJSONValue().toString());
        }

    }
    return 0;
}
