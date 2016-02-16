module run_tests;

import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.range;
import messages;

import std.conv;
import std.json;
import msgpack;

import dastedserver;

import find_declaration_simple;

int main(string[] args)
{
    string dmdconf;
    string importDirectories;
    string directory;
    string[] disableMsg;
    string[] enableMsg;
    string logLevel;
    bool run = false;

    getopt(args,
        "d|directory", &directory,
        "i|imports", &importDirectories,
        "r|run", &run,
        "dmdconf", &dmdconf,
        "disable_msg", &disableMsg,
        "enable_msg", &enableMsg,
        "log_level", &logLevel);

    auto d = new Dasted;

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

    if (run)
    {
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
