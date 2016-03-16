sig LINEARProgram {
  mainFunction: one MainFunction,
  functions: some Function, // at least the mainFunction
}

sig Function {
  returnType: one Type,
  firstStmt: one Statement,
  returnStmt: one ReturnStatement,
  formals: set FormalParameter, // may have no formal parameters
}

one sig MainFunction extends Function {}

sig Statement {
  predecessor: lone Statement,
  successor: lone Statement,
}
fact {predecessor = ~successor}

sig AssignStatement extends Statement {
  left: one VariableReference,
  right: one Expr,
} // {p_subTypeOf[left.Type, right.Type]}

sig ReturnStatement extends Statement {
} {no successor}

sig VarDecl extends Statement {
  var: one Variable,
}

sig FormalParameter {}

sig Expr {
  parentExpr: lone Expr,
  children: set Expr, // may have zero children
}
fact {parentExpr = ~children}

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

sig Variable {}

/*
 * Functions and predicates below express
 * "what I want them to do"
 * and probably do not work just yet
 * - @limenet
 */

/*

fun p_numFunctionCalls: Int {}

fun p_expressionTypes: set Type {}

fun p_statementsInFunction [f: Function]: set Statement {}

fun p_statementsAfter [s: Statement]: set Statement {}

fun p_parameters [f: Function]: FormalParameter {}

fun p_subExprs [e: Expr]: set Expr {}


pred p_containsCall [f: Function] {}

pred p_isAssigned [v: Variable] {
    v in one AssignStatement.left
}

pred p_isRead [v: Variable] {
    v in some VariableReference
}

pred p_isDeclared [v: Variable] {
    v in one VarDecl
}

pred p_isParameter [v: Variable] {
    v in Function.formalParams
}

pred p_subtypeOf [t1: Type, t2: Type] {
    t1.parent = t2
}

pred p_assignsTo [s: Statement, vd: VarDecl] {}

*/
