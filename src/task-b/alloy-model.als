// ---------- Instances for task C --------------------------------------------------- //

pred inst1 {}
run inst1 for 5 but exactly 2 CallExpr, 1 Function

pred inst2 {}
run inst2 for 5 but exactly 2 CallExpr, 2 Function

pred inst3 {
  one AssignStatement
  one Literal
  one Variable
}
run inst3

pred inst4 {
  some a: AssignStatement, ce: a.assignedValue {
    ce in CallExpr
    all vd: VarDecl | p_assignsTo[a, vd] implies disj[ce.function.returnStmt.returnValue.type, ce.function.returnType, vd.type]
  }
}
run inst4 for 5 but exactly 1 CallExpr

pred inst5 {
  one Literal
  all disj t1, t2: Type | t1 != t2.supertype
}
run inst5 for 5 but exactly 2 Type

// ---------- Static Model of task B -------------------------------------------------- //

pred show {
  (some f: Function | f not in MainFunction) &&
  (some AssignStatement)
}
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
  assignedTo: one Variable, // writes value "directly" to the variable
  assignedValue: disj one Expr,
}

sig ReturnStatement extends Statement {
  returnValue: disj one Expr, // A return statement carries an expression that defines which value is returned by the function.
}

sig VarDecl extends Statement {
  declaredVar: disj one Variable, // the variable can't be evalutated to a value yet and is therefore not seen as an expression
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
}

sig CallExpr extends Expr {
  function: one Function, // A function can be called in a corresponding call expression.
  actuals: Expr lone -> lone FormalParameter, // A call expression is assiociated with a set of expressions that serve as actual parameters and are mapped to formal parameters.
}

sig Literal extends Expr {} // We do not model the value of literals.

sig VariableReference extends Expr {
  referredVar: one Variable, // reads value from the variable
}

sig Type {
  supertype: lone Type, // Each type can have up to one supertype.
  subtypes: disj set Type,
}

sig Variable {}

/* --------------------------------------------------------------------------------
 * Facts
 * -------------------------------------------------------------------------------- */

fact {
  (Function.statements = Statement) && // all statements belong to a function
  ((Statement.exprs + Expr.children) = Expr) && // all expressions have a parent
  (no (Statement.exprs & Expr.children)) && (no (Statement.assignedValue & Statement.returnValue)) &&
  (all disj f1, f2: Function | disj[f1.statements.subExprs.referredVar, f2.statements.subExprs.referredVar]) // TODO: all variables are local to a function
}

// Functions consist of a linear sequence of statements.
fact {
  (predecessor = ~successor) && (all s: Statement | s != s.predecessor) && // predecessor/successor relationship is not reflexive
  (all f: Function | no f.firstStmt.predecessor) && // the first statement has no predecessor
  (all f: Function | f.returnStmt in p_statementsInFunction[f])
}

// Actual parameters are mapped to formal parameters.
fact {
  (all ce: CallExpr | #ce.actuals = #ce.function.formals) // number of arguments match
}

// TODO: A return statement terminates the execution of the function body. Not a static constraint.

// A function may not contain unreachable statements. i.e. the return statement has no successor statement.
fact {
  all rs: ReturnStatement | no p_statementsAfter[rs]
}

// Recursion is not allowed.
fact {
  no f: Function | f in f.^functions
}

// There is one main function that takes no parameters.
fact {
  no MainFunction.formals
}

// There is one main function from which all other functions are transitively called.
fact {
  Function in MainFunction.*functions
}

// Variables are declared exactly once, either in a corresponding declaration statement or as function parameter.
fact {
  all v: Variable | p_isDeclared[v]
}

// TODO: Declaration statements must appear in the same function before the first use.
fact {
//  all vd: VarDecl | vd.declaredVar not in (VariableReference - p_statementsAfter[vd].subExprs).referredVar
}

// A variable that has been declared can be assigned to using an assignment statement.
fact {
  all vd: VarDecl | all a: AssignStatement | p_assignsTo[a, vd] implies (a in p_statementsAfter[vd])
}

// Once the variable has been assigned to, it can be used in expressions in subsequent statements.
fact {
  no a: AssignStatement | a.assignedTo in (VariableReference - p_statementsAfter[a].subExprs).referredVar
}

// We do not allow dead variables (variables that are never read).
fact {
  all v: Variable | p_isRead[v]
}

// We do not allow dead assignments (assignments that are not followed by a read of the variable).
fact {
  all a: AssignStatement | a.assignedTo in p_statementsAfter[a].subExprs.referredVar
}

// Parameters should never be assigned to.
fact {
  all v: Variable | p_isParameter[v] implies (!p_isAssigned[v])
}

// Expressions form trees, and nodes of expression trees are never shared, i.e. every node has a unique parent.
fact {
  (parent = ~children) && (all e: Expr | e != e.parent) && // parent/children relationship is not reflexive
  (children = {c: CallExpr, e: Expr | c->e->FormalParameter in actuals}) // children of CallExpr are actuals: link them to actual parent/child expressions
}

// The usual typing rules apply to assignments, function calls and return statements.
fact {
  (supertype = ~subtypes) && (all t: Type | t != t.supertype) && // supertye/subtypes relationship is not reflexive
  (all a: AssignStatement | all vd: VarDecl | p_assignsTo[a, vd] implies p_subtypeOf[a.assignedValue.type, vd.type]) &&
  (#{e: Expr, f: FormalParameter | CallExpr->e->f in actuals && p_subtypeOf[e.type, f.type]} = #actuals) && // TODO
  (all f: Function | p_subtypeOf[f.returnStmt.returnValue.type, f.returnType])
}

// TODO: all vr: VariableReference | all vd: VarDecl | (vr.referredVar = vd.declaredVar) implies vr.type = vd.type

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
  f.statements
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
  some CallExpr & p_statementsInFunction[f].exprs
}

// true iff v appears on the left side of an assignment anywhere in the program.
pred p_isAssigned [v: Variable] {
  v in AssignStatement.assignedTo
}

// true iff v appears in an expression anywhere in the program. Exclude writes.
pred p_isRead [v: Variable] {
  v in VariableReference.referredVar
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

// true iff t1 is a subtype of t2. Returns true if types are equal. TODO: do they want type equality to be included or not?
pred p_subtypeOf [t1: Type, t2: Type] {
  t2 in t1.*supertype
}

// true iff s assigns to the variable declared by vd.
pred p_assignsTo [s: Statement, vd: VarDecl] {
  s.assignedTo = vd.declaredVar
}

/* --------------------------------------------------------------------------------
 * Additional Relations
 * -------------------------------------------------------------------------------- */

// Returns tuples of the form (caller, callee): (Function, Function), i.e. the function caller calls the function calle in its body.
fun functions: set Function -> Function {
  (statements.subExprs :> CallExpr).function
}

// Returns tuples of functions and their statements.
fun statements: set Function -> Statement {
  firstStmt.*successor
}

// Returns tuples of statements and their direct subexpressions.
fun exprs: set Statement -> Expr {
  assignedValue + returnValue
}

// Returns tuples of statements and all their subexpressions.
fun subExprs: set Statement -> Expr {
  exprs.*children
}
