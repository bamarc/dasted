module attributeutils;

import dsymbols.common;
import logger;

import dparse.ast;

import std.array;

alias AttributeList = const(Attribute)[];

Visibility getVisibility(Visibility viz, AttributeList attrs)
{
    auto result = viz;
    while (!attrs.empty())
    {
        auto a = attrs.back();
        if (a !is null)
        {
            switch (a.attribute.type)
            {
            case tok!"private": result = Visibility.PRIVATE; return result;
            case tok!"public": result = Visibility.PUBLIC; return result;
            case tok!"protected": result = Visibility.PROTECTED; return result;
            case tok!"package": result = Visibility.PACKAGE; return result;
            default: break;
            }
        }
        attrs.popBack();
    }
    return result;
}
