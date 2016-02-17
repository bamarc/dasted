module find_declaration_simple;

import engine;
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
