module attributeutils;

import dsymbols.common;
import std.array;

alias AttributeList = const(Attribute)[];

struct AttributeStackGuard
{
    this(AttributeList* stack, AttributeList attr)
    {
        _attributes = stack;
        if (!attr.empty())
        {
            (*_attributes) ~= attr;
            _num = attr.length;
        }
    }

    ~this()
    {
        if (_num > 0)
        {
            (*_attributes) = (*_attributes)[0..$ - _num];
        }
    }
    typeof(AttributeList.init.length) _num;
    AttributeList* _attributes;
}

Visibility getVisibility(Visibility viz, AttributeList attrs)
{
    return Visibility.PUBLIC;
}
