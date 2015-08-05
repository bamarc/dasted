import modulecache;
import convert;

int main(string[] args)
{
    assert(args.length == 2);

    import std.stdio;
    auto ch = new ModuleCache;
    auto st = ch.get(args[1]);
    writeln(st.dmodule.astString());

    return 0;
}
