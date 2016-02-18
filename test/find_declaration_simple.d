module find_declaration_simple;

import engine;
import dsymbols.common;
import test_common;

import std.stdio;

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        string |test = "Hello world";
        auto another = t|est ~ ", worldy world";
        EOF)";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbol = engine.findDeclaration(srcPos.pos[1]);

    assert(symbol !is null);
    assert(symbol.name() == "test");
    assert(symbol.position() == srcPos.pos[0]);
    assert(symbol.type().builtin == false);
    assert(symbol.type().asString() == "string");
}

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        int |test = 5;
        auto another = t|est + 10;
        EOF)";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbol = engine.findDeclaration(srcPos.pos[1]);

    assert(symbol !is null);
    assert(symbol.name() == "test");
    assert(symbol.position() == srcPos.pos[0]);
    assert(symbol.type().builtin == true);
    assert(symbol.type().asString() == "int");
}

unittest
{
    Engine engine = new Engine;
    string sources = q"(
        bool |param_a = true;
        int |foo(int |param_a, int param_b)
        {
            return par|am_a;
        }
        auto another = f|oo(par|am_a);
        EOF)";
    auto srcPos = getSourcePos(sources);
    engine.setSource("test", srcPos.src, 0);

    auto symbol1 = engine.findDeclaration(srcPos.pos[3]);

    assert(symbol1 !is null);
    assert(symbol1.name() == "param_a");
    assert(symbol1.position() == srcPos.pos[2]);
    assert(symbol1.type().builtin == true);
    assert(symbol1.type().asString() == "int");
    assert(symbol1.parent.name() == "foo");

    auto symbol2 = engine.findDeclaration(srcPos.pos[4]);

    assert(symbol2 !is null);
    assert(symbol2.name() == "foo");
    assert(symbol2.position() == srcPos.pos[1]);
    // TODO: type check?
    assert(symbol2.parent.symbolType() == SymbolType.MODULE);

    auto symbol3 = engine.findDeclaration(srcPos.pos[5]);

    assert(symbol3 !is null);
    assert(symbol3.name() == "param_a");
    assert(symbol3.position() == srcPos.pos[0]);
    assert(symbol3.type().builtin == true);
    assert(symbol3.type().asString() == "bool");
    assert(symbol3.parent.symbolType() == SymbolType.MODULE);
}
