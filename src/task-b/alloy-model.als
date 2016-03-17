pred show {}
run show

/* --------------------------------------------------------------------------------
 * Signatures
 * -------------------------------------------------------------------------------- */

sig LINEARProgram {
  mainFunction: one MainFunction,
  functions: some Function,
  // TODO: decide whether mainFunction is in functions
  // some -> at least the mainFunction or set -> if not contained
}

sig Function {
  returnType: one Type,
  firstStmt: one Statement,
  returnStmt: one ReturnStatement,
  formals: set FormalParameter, // may have no formal parameters
}
// TODO: functions can't be shared between programs

one sig MainFunction extends Function {}

sig Statement {
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
  variable: one Variable,
  type: one Type,
}

sig FormalParameter {
  variable: one Variable,
  type: one Type,
}

sig Expr {
  parent: lone Expr,
  children: set Expr, // may have zero children
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

/*
 * Functions and predicates below express
 * "what I want them to do"
 * and probably do not work just yet
 * - @limenet
 *
 * commented out code contains syntax/type errors
 */

/* --------------------------------------------------------------------------------
 * Functions
 * -------------------------------------------------------------------------------- */

// Returns the number of function calls in the program.
// TODO: Given this description, I suppose that we don't need to model programs as a signature, right?
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
fun p_parameters [f: Function]: FormalParameter {
  f.formals
}

// Returns the direct subexpressions of e.
fun p_subExprs [e: Expr]: set Expr {
  e.children
}

/* --------------------------------------------------------------------------------
 * Predicates
 * -------------------------------------------------------------------------------- */


pred p_containsCall [f: Function] {}

pred p_isAssigned [v: Variable] {
//    v in one AssignStatement.left
}

pred p_isRead [v: Variable] {
//    v in some VariableReference
}

pred p_isDeclared [v: Variable] {
//    v in one VarDecl
}

pred p_isParameter [v: Variable] {
//    v in Function.formalParams
}

pred p_subtypeOf [t1: Type, t2: Type] {
//    t1.parent = t2
}

pred p_assignsTo [s: Statement, vd: VarDecl] {}
