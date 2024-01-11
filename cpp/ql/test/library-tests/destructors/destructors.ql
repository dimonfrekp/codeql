import cpp

query predicate exprDestructors(Expr e, int i, DestructorCall d, Expr destructed) {
    d = e.getSyntheticDestructor(i) and
    d.getQualifier() = destructed
}

query predicate stmtDestructors(Stmt s, int i, DestructorCall d, Expr destructed) {
    d = s.getSyntheticDestructor(i) and
    d.getQualifier() = destructed
}