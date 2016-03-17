pred show {}
run show

/* --------------------------------------------------------------------------------
 * Signatures
 * -------------------------------------------------------------------------------- */

sig Function {
  returnType: one Type,
  firstStmt: disj one Statement,
  returnStmt: disj one ReturnStatement,
  formals: disj set FormalParameter, // may have no formal parameters
}

one sig MainFunction extends Function {}

abstract sig Statement {
  predecessor: lone Statement,
  successor: lone Statement,
}
fact {predecessor = ~successor} // TODO: link them to actual predecessor/successor statements
// TODO: statements can't be shared between functions

sig AssignStatement extends Statement {
  left: one VariableReference,
  right: one Expr,
} // {p_subTypeOf[left.Type, right.Type]}
fact {left.type = right.type} // TODO

sig ReturnStatement extends Statement {
  returnValue: one Expr,
} {no successor}

sig VarDecl extends Statement {
  variable: disj one Variable, // disj: declared by at most one VarDecl statement
  type: one Type,
}

sig FormalParameter {
  variable: disj one Variable, // disj: declared by at most one FormalParameter
  type: one Type,
}

abstract sig Expr {
  parent: lone Expr,
  children: set Expr, // may have zero direct children
  type: one Type,
}
fact {parent = ~children} // TODO: link them to actual parent/child expressions
// TODO: expresssions are exclusively owned by another expression or a statement

sig CallExpr extends Expr {
  actuals: set Expr,
}

sig Literal extends Expr {}

sig VariableReference extends Expr {
  refersTo: one Variable,
}

sig Type {
  supertype: lone Type,
  subtypes: set Type,
}
fact {supertype = ~subtypes}

sig Variable {}

/* --------------------------------------------------------------------------------
 * Facts
 * -------------------------------------------------------------------------------- */

// Variables are declared exactly once.
fact {
  all v: Variable | p_isDeclared[v]
}

/* --------------------------------------------------------------------------------
 * Functions
 * -------------------------------------------------------------------------------- */

// Returns the number of function calls in the program.
fun p_numFunctionCalls: Int {
  #CallExpr
}

// Returns the types of all expressions.
fun p_expressionTypes: set Type {
  Expr.type
}

// Returns the types of all literals.
fun p_literalTypes: set Type {
  Literal.type
}

// Returns all statements directly contained in the body of a function.
fun p_statementsInFunction [f: Function]: set Statement {
  f.firstStmt.*successor
}

// Returns all statements contained after s in the same function.
fun p_statementsAfter [s: Statement]: set Statement {
  s.^successor
}

// Returns the formal parameters of function f.
fun p_parameters [f: Function]: set FormalParameter {
  f.formals
}

// Returns the direct subexpressions of e.
fun p_subExprs [e: Expr]: set Expr {
  e.children
}

/* --------------------------------------------------------------------------------
 * Predicates
 * -------------------------------------------------------------------------------- */

// true iff f contains a function call directly in its body.
pred p_containsCall [f: Function] {
  some CallExpr & p_statementsInFunction[f].containsExpr
}

// true iff v appears on the left side of an assignment anywhere in the program.
pred p_isAssigned [v: Variable] {
  v in AssignStatement.left.refersTo
}

// true iff v appears in an expression anywhere in the program.
pred p_isRead [v: Variable] {
  v in VariableReference.refersTo
}

// true iff v is declared exactly once.
pred p_isDeclared [v: Variable] {
  (v in (VarDecl.variable + FormalParameter.variable)) && // at least once
  (v not in (VarDecl.variable & FormalParameter.variable)) // at most once
}

// true iff v is declared as a parameter.
pred p_isParameter [v: Variable] {
  v in FormalParameter.variable
}

// true iff t1 is a subtype of t2. Returns true if types are equal.
pred p_subtypeOf [t1: Type, t2: Type] {
  t2 in t1.*supertype
}

// true iff s assigns to the variable declared by vd.
pred p_assignsTo [s: Statement, vd: VarDecl] {
  s.left.refersTo = vd.variable
}

/* --------------------------------------------------------------------------------
 * Helper Functions
 * -------------------------------------------------------------------------------- */

// Returns tuples of statements and their direct subexpressions.
fun containsExpr: set Statement -> Expr {
  left + right + returnType
} // TODO: do we really need to distinguish between Variables and VariableReferences? The Variable field in a VarDecl would also be an Expr.
