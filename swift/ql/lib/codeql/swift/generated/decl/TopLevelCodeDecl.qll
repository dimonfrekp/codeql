// generated by codegen/codegen.py
import codeql.swift.elements.stmt.BraceStmt
import codeql.swift.elements.decl.Decl

class TopLevelCodeDeclBase extends @top_level_code_decl, Decl {
  override string getAPrimaryQlClass() { result = "TopLevelCodeDecl" }

  BraceStmt getBody() {
    exists(BraceStmt x |
      top_level_code_decls(this, x) and
      result = x.resolve()
    )
  }
}
