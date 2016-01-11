module logger;
static if (__traits(compiles, {
    import std.experimental.logger;
}))
{
    import std.experimental.logger;
}
else
{
    public import std.stdio;
    public alias log = writeln;
}

import std.conv;
import std.regex;
import std.string;
import std.typecons;

private bool[Tuple!(string, int)] _traces;
private Tuple!(string, bool)[] _conditions;

void toggleLogMsg(string regex, bool enable)
{
    _conditions ~= tuple(regex, enable);
}

void setLogLevel(string lv)
{
    auto l = LogLevel.info;
    try
    {
        auto lvLower = lv.toLower();
        l = to!LogLevel(lvLower);
    }
    catch
    {
        warning("Unknown log level ", lv, " (info will be used).");
    }
    globalLogLevel(l);
}


alias trace = _logFilterHelper!(std.experimental.logger.trace);
alias info = _logFilterHelper!(std.experimental.logger.info);
alias warning = _logFilterHelper!(std.experimental.logger.warning);
alias error = _logFilterHelper!(std.experimental.logger.error);
alias critical = _logFilterHelper!(std.experimental.logger.critical);
alias fatal = _logFilterHelper!(std.experimental.logger.fatal);
alias log = trace;


template _logFilterHelper(alias T)
{
    void _logFilterHelper(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__, A...)(lazy A args)
    {
        auto t = tuple(file, line) in _traces;
        auto enable = true;
        if (t is null)
        {
            foreach (cond; _conditions)
            {
                auto rx = regex(cond[0]);
                if (match(file ~ ":" ~ to!string(line), rx))
                {
                    enable = cond[1];
                }
            }
            _traces[tuple(file, line)] = enable;
        }
        else
        {
            enable = *t;
        }
        if (enable)
        {
            T!(line, file, funcName,
                prettyFuncName, moduleName)(args);
        }
    }
}
