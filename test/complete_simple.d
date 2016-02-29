module complete_simple;

import engine;
import dsymbols.common;
import test_common;

import std.algorithm;
import std.stdio;

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        interface |ISimple // 0
        {
            ISimple |foo();
            const(ISimple) |foo() const;
        }

        struct A
        {
            class |B : ISimple
            {
                class |C
                {
                    B |c_member; // 5
                }
                int |b_member;
            }
            C |a_member; // 7
        }
        const(A.B.C) c = null;
        c.|c_mem|ber.|b_|member = 5;
        )";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbol_c_dot = engine.complete(srcPos.pos[8]);
    auto symbol_c_complete = engine.complete(srcPos.pos[9]);

    assert(symbol_c_dot[1] == false);
    assert(symbol_c_dot[0].length == 1);
    assert(symbol_c_complete[1] == false);
    assert(symbol_c_complete[0].length == 1);
    assert(symbol_c_dot[0].equal!((a, b) => a.name() == b.name()
                                            && a.position == b.position)(
           symbol_c_complete[0]));
    auto symbol = symbol_c_dot[0][0];
    assert(symbol.name() == "c_member");
    assert(symbol.position() == srcPos.pos[5]);
    assert(symbol.type().builtin == false);
    assert(symbol.type().asString() == "B");
    auto btypes = symbol.type().find(symbol);
    assert(btypes.length == 1);
    assert(btypes[0].name() == "B");

    auto symbol_b_dot = engine.complete(srcPos.pos[10]);
    assert(symbol_b_dot[1] == false);
    assert(symbol_b_dot[0].length == 4);
    assert(symbol_b_dot[0].map!(a => a.name()).isPermutation(["foo", "foo", "C", "b_member"]));
    assert(symbol_b_dot[0].filter!(a => a.name() == "foo")
                          .map!(a => a.position)
                          .isPermutation([srcPos.pos[1], srcPos.pos[2]]));
    assert(symbol_b_dot[0].filter!(a => a.name() == "C")
                          .map!(a => a.position)
                          .equal([srcPos.pos[4]]));

    auto symbol_b_complete = engine.complete(srcPos.pos[11]);
    assert(symbol_b_complete[1] == false);
    assert(symbol_b_complete[0].length == 1);
    assert(symbol_b_complete[0][0].name() == "b_member");
}

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        class |ISimple // 0
        {
            ISimple |foo(int a, ISimple b); // 1
            const(ISimple) |foo(ISimple c) const; // 2
        }

        ISimple |a_inst = new ISimple; // 3
        auto res = a_inst.|foo(|0,| a|_inst); // 4, 5, 6, 7
        )";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbols = engine.complete(srcPos.pos[4]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 2);
    assert(symbols[0].map!(a => a.name()).equal(["foo", "foo"]));
    assert(symbols[0].map!(a => a.position).isPermutation([srcPos.pos[1], srcPos.pos[2]]));

    auto symbol_b_complete1 = engine.complete(srcPos.pos[5]);
    assert(symbol_b_complete1[1] == true);
    assert(symbol_b_complete1[2] == 0);
    assert(symbol_b_complete1[0].length == 2);
    assert(symbol_b_complete1[0].all!(a => a.name() == "foo"));
    assert(symbol_b_complete1[0].map!(a => a.parameters.length).isPermutation([1, 2]));

    auto symbol_b_complete2 = engine.complete(srcPos.pos[6]);
    assert(symbol_b_complete2[1] == true);
    assert(symbol_b_complete2[2] == 1);
    assert(symbol_b_complete2[0].length == 2);
    assert(symbol_b_complete1[0][0] is symbol_b_complete2[0][0]);
    assert(symbol_b_complete1[0][1] is symbol_b_complete2[0][1]);

    auto symbol_a_inst_complete = engine.complete(srcPos.pos[7]);
    assert(symbol_a_inst_complete[1] == false);
    assert(symbol_a_inst_complete[0].length == 1);
    assert(symbol_a_inst_complete[0][0].name() == "a_inst");
    assert(symbol_a_inst_complete[0][0].dotAccess().map!(a => a.name())
                                       .equal(["foo", "foo"]));
}

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        class A { int |m; } // 0
        A model;
        auto a = model;
        a.|m = 5;           // 1
        auto b = a.m;
        b| = 6;             // 2
        )";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbols = engine.complete(srcPos.pos[1]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 1);
    assert(symbols[0][0].name() == "m");
    assert(symbols[0][0].position() == srcPos.pos[0]);

    symbols = engine.complete(srcPos.pos[2]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 1);
    assert(symbols[0][0].name() == "b");
    assert(symbols[0][0].type().builtin == false);
    assert(symbols[0][0].type().evaluate !is null);
    symbols[0] = symbols[0][0].type().evaluate.evaluate();
    assert(symbols[0].length == 1);
    assert(symbols[0][0].type().asString() == "int");
}

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        class A
        {
            this() {}
            this(int a) { m = a; }
            int |m;                 // 0
        }
        auto a = new A;
        a.|m = 5;                   // 1
        auto b = new A(4);
        b.|m = 6;                   // 2
        )";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbols = engine.complete(srcPos.pos[1]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 1);
    assert(symbols[0][0].name() == "m");
    assert(symbols[0][0].position() == srcPos.pos[0]);

    symbols = engine.complete(srcPos.pos[2]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 1);
    assert(symbols[0][0].name() == "m");
}

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        struct A
        {
            this(int a) { m = a; }
            int |m;                 // 0
        }
        auto a = A();
        a.|m = 5;                   // 1
        auto b = A(4);
        b.|m = 6;                   // 2
        )";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbols = engine.complete(srcPos.pos[1]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 1);
    assert(symbols[0][0].name() == "m");
    assert(symbols[0][0].position() == srcPos.pos[0]);

    symbols = engine.complete(srcPos.pos[2]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 1);
    assert(symbols[0][0].name() == "m");
}

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        module test.a.b;
        import test.|;
        )";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbols = engine.complete(srcPos.pos[0]);

    assert(symbols[1] == false);
    assert(symbols[0].length == 0);
}
