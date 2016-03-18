pred show {}
run show

/* --------------------------------------------------------------------------------
 * Signatures
 * -------------------------------------------------------------------------------- */

sig Function {
  returnType: one Type, // Functions have a return type.
  firstStmt: disj one Statement,
  returnStmt: disj one ReturnStatement, // Each function execution must be terminated by a return statement.
  formals: disj set FormalParameter, // Functions have a set (may be zero) of formal parameters with types.
}

one sig MainFunction extends Function {}

abstract sig Statement {
  predecessor: disj lone Statement,
  successor: disj lone Statement,
}

sig AssignStatement extends Statement {
  left: disj one VariableReference,
  right: disj one Expr,
}

sig ReturnStatement extends Statement {
  returnValue: disj one Expr, // A return statement carries an expression that defines which value is returned by the function.
}

sig VarDecl extends Statement {
  declaredVar: disj one Variable,
  type: one Type, // Declaration statements declare variables of a specific type.
}

sig FormalParameter {
  declaredVar: disj one Variable,
  type: one Type,
}

abstract sig Expr {
  parent: lone Expr,
  children: disj set Expr, // may have zero direct children
  type: one Type, // Expressions are typically associated with a type.
  formal: lone FormalParameter,
}

sig CallExpr extends Expr {
  function: one Function, // A function can be called in a corresponding call expression.
  actuals: disj set Expr, // A call expression is assiociated with a set of expressions that serve as actual parameters.
}

sig Literal extends Expr {} // We do not model the value of literals.

sig VariableReference extends Expr {
  referredVar: one Variable,
}

sig Type {
  supertype: lone Type, // Each type can have up to one supertype.
  subtypes: disj set Type,
}

sig Variable {}

/* --------------------------------------------------------------------------------
 * Facts
 * -------------------------------------------------------------------------------- */

// Functions consist of a linear sequence of statements.
fact {
  (predecessor = ~successor) &&
  (all f: Function | f.returnStmt in f.firstStmt.*successor) && // take reflexive, transitive closure to allow functions with only one statement
  (all s: Statement | s != s.successor) // not reflexive
}
/*
// Actual parameters are mapped to formal parameters.
fact {
  (usedAsFormal = ~usedAsActual) &&
  (CallExpr.actuals = FormalParameter.usedAsFormal) && // connect expressions to formals
  (all ce: CallExpr | #ce.actuals = #ce.function.formals) // number of arguments match
}
*/
// A return statement terminates the execution of the function body.
// A function may not contain unreachable statements. i.e. the return statement has no successor statement.
fact {
  all rs: ReturnStatement | no p_statementsAfter[rs]
}

// The first statement has no predecessor.
fact {
  all f: Function | no f.firstStmt.predecessor
}
/*
// Recursion is not allowed.
fact {
  all f: Function | f not in f.functionCalls
}

// There is one main function that takes no parameters.
fact {
  no MainFunction.formals
}

// TODO: There is one main function from which all other functions are transitively called.
fact {
  all f: (Function - MainFunction) | f in MainFunction.^functionCalls
}

// Variables are declared exactly once, either in a corresponding declaration statement or as function parameter.
fact {
  all v: Variable | p_isDeclared[v]
}

// TODO: Declaration statements must appear in the same function before the first use.

// TODO: A variable that has been declared can be assigned to using an assignment statement.

// TODO: Once the variable has been assigned to, it can be used in expressions in subsequent statements.

// We do not allow dead variables (variables that are never read).
fact {
  all v: Variable | p_isRead[v]
}

// We do not allow dead assignments (assignments that are not followed by a read of the variable).
fact {
  all a: AssignStatement | a.left.referredVar in p_statementsAfter[a].(containsExpr.*children.referredVar - left.referredVar)
}

// Parameters should never be assigned to.
fact {
  all v: Variable | p_isParameter[v] implies not p_isAssigned[v]
}

// Expressions form trees, and nodes of expression trees are never shared, i.e. every node has a unique parent.
fact {
  (parent = ~children) &&
  (actuals = children) // children of CallExpr are actuals: link them to actual parent/child expressions
}

// The usual typing rules apply to assignments, function calls and return statements.
fact {
  (supertype = ~subtypes) &&
  (all a: AssignStatement | p_subtypeOf[a.right.type, a.left.type]) &&
  (all ce: CallExpr, a: ce.actuals | p_subtypeOf[a.type, a.usedAsActual.type]) &&
  (all f1: Function | p_subtypeOf[f1.returnStmt.returnValue.type, f1.type])
}
*/
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
  v in AssignStatement.left.referredVar
}

// true iff v appears in an expression anywhere in the program. Exclude writes.
pred p_isRead [v: Variable] {
  v in (VariableReference.referredVar - AssignStatement.left.referredVar)
}

// true iff v is declared exactly once.
pred p_isDeclared [v: Variable] {
  (v in (VarDecl.declaredVar + FormalParameter.declaredVar)) && // at least once
  (v not in (VarDecl.declaredVar & FormalParameter.declaredVar)) // at most once
}

// true iff v is declared as a parameter.
pred p_isParameter [v: Variable] {
  v in FormalParameter.declaredVar
}

// true iff t1 is a subtype of t2. Returns true if types are equal.
pred p_subtypeOf [t1: Type, t2: Type] {
  t2 in t1.*supertype
}

// true iff s assigns to the variable declared by vd.
pred p_assignsTo [s: Statement, vd: VarDecl] {
  s.left.referredVar = vd.declaredVar
}

/* --------------------------------------------------------------------------------
 * Helper Functions
 * -------------------------------------------------------------------------------- */

// Returns tuples of statements and their direct subexpressions.
fun containsExpr: set Statement -> Expr {
  left + right + returnType
} // TODO: The Variable field in a VarDecl would also be an Expr?

// Returns tuples of functions and the called functions.
fun functionCalls: set Function -> Function {
  (firstStmt.*successor.containsExpr.*children :> CallExpr).function
}
