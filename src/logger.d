module logger;
static if (__traits(compiles, {
    import std.experimental.logger;
}))
{
    public import std.experimental.logger;
}
else
{
    public import std.stdio;
    public alias log = writeln;
}
