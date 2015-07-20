module dsymbols.dtemplate;

import dsymbols.common;

import std.algorithm;
import std.array;

DSymbol[] fromNode(const TemplateDeclaration decl)
{
    return [new TemplateSymbol(decl)];
}

class TemplateSymbol : DASTSymbol!(SymbolType.TEMPLATE, TemplateDeclaration)
{
    this(const TemplateDeclaration decl)
    {
        super(decl);
    }
}
