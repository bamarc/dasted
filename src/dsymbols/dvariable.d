module dsymbols.dvariable;

import dsymbols.common;

import std.array;
import std.algorithm;

DSymbol[] fromNode(const VariableDeclaration decl, SymbolState state)
{
    return array(map!(a => fromNode(decl, a))(decl.declarators));
}

DSymbol fromNode(const VariableDeclaration v, const Declarator d)
{
    return new VariableSymbol(v, d);
}

class VariableSymbol : DASTSymbol!(SymbolType.VAR, VariableDeclaration)
{
    const Declarator _decl = null;
    this(const VariableDeclaration v, const Declarator d)
    {
        super(v);

        info.name = d.name.text.idup;
        info.type = toDType(v.type);
        info.position.offset = cast(Offset)d.name.index;
    }
}

class EnumVariableSymbol : DASTSymbol!(SymbolType.ENUM, EnumMember)
{
    this(const EnumMember mem)
    {
       super(mem);
    }
}
