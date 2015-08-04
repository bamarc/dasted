module dsymbols.dmodule;

import dsymbols.common;
import dsymbols.dfunction;

import std.array;
import std.algorithm;
import std.exception;

DSymbol[] fromNode(const Module decl, SymbolState state)
{
    return [new ModuleSymbol(decl)];
}

class ModuleSymbol : DASTSymbol!(SymbolType.MODULE, Module)
{
    this(const(Module) mod)
    {
        enforce(mod !is null, "invalid Module");
        super(mod);
        if (mod.moduleDeclaration !is null && mod.moduleDeclaration.moduleName !is null)
        {
            info.name = join(map!(a => a.text.idup)(mod.moduleDeclaration.moduleName.identifiers), ".");
        }
        info.position.offset = 0;
    }

    override string fileName() const
    {
        return _filename;
    }

    void setFileName(string value)
    {
        _filename = value;
    }

    private string _filename;

}
