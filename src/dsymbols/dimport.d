module dsymbols.dimport;

import dsymbols.common;

import std.array;
import std.algorithm;

ImportSymbol[] fromNode(const ImportDeclaration decl, SymbolState state)
{
    return array(filter!(a => a !is null)(map!(a => fromSingleImportNode(a, state))(decl.singleImports)));
}

ImportSymbol fromSingleImportNode(const SingleImport imp, SymbolState state)
{
    return new ImportSymbol(imp, state);
}

class ImportSymbol : DASTSymbol!(SymbolType.MODULE, SingleImport)
{
    this(const NodeType decl, SymbolState state)
    {
        super(decl);

        if (decl.identifierChain is null || decl.identifierChain.identifiers.empty())
        {
            return;
        }
        info.name = join(array(map!(a => a.text.idup)(decl.identifierChain.identifiers)), ".");
        info.position.offset = cast(Offset)decl.identifierChain.identifiers.front().index;
    }

    override void addToParentImpl(DSymbol parent)
    {
        parent.add(this);
        parent.adopt(this);
    }
}
