// generated by codegen/codegen.py
import codeql.swift.elements.stmt.BraceStmt
import codeql.swift.elements.stmt.Stmt

class DeferStmtBase extends @defer_stmt, Stmt {
  override string getAPrimaryQlClass() { result = "DeferStmt" }

  BraceStmt getBody() {
    exists(BraceStmt x |
      defer_stmts(this, x) and
      result = x.resolve()
    )
  }
}
