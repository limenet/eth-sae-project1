// ---------- Instances for task C --------------------------------------------------- //

// A program with one function, 2 function calls.
pred inst1 {}
run inst1 for 5 but exactly 2 CallExpr, 1 Function

// A program with two functions, 2 function calls.
pred inst2 {}
run inst2 for 5 but exactly 2 CallExpr, 2 Function

// A program with exactly 1 assignment, 1 variable, 1 literal (no restrictions on other kinds of expressions).
pred inst3 {
  one AssignStatement
  one Literal
  one Variable
}
run inst3

// A program with exactly 1 function call, which is on the right-hand side of an assignment.
// The expression inside the called function’s return statement is of a different type than the return type of the function,
// and both are different from the type of the variable on the left-hand side of the assignment.
pred inst4 {
  some a: AssignStatement, ce: a.assignedValue {
    ce in CallExpr
    all vd: VarDecl | p_assignsTo[a, vd] implies disj[ce.function.returnStmt.returnValue.type, ce.function.returnType, vd.type]
  }
}
run inst4 for 5 but exactly 1 CallExpr

// A program with exactly 1 literal and exactly 2 incomparable types.
pred inst5 {
  one Literal
  all disj t1, t2: Type | t1 != t2.supertype
}
run inst5 for 5 but exactly 2 Type

// ---------- Static Model of task B -------------------------------------------------- //

pred show {}
run show for 5

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
  type: one Type, // Expressions are associated with a type.
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
 * Facts (Static Model)
 * -------------------------------------------------------------------------------- */

// Functions consist of a linear sequence of statements.
fact {
  (predecessor = ~successor) &&
  (Function.statements = Statement) && // all statements belong to a function
  (no firstStmt.predecessor) && // the first statement has no predecessor
  (all f: Function | f.returnStmt in p_statementsInFunction[f]) &&
  (no ReturnStatement.successor) // A function may not contain unreachable statements. i.e. the return statement has no successor statement.
}

// Expressions are typically associated with a type.
fact {
  (all ce: CallExpr | ce.type = ce.function.returnType) && // The type of a call expression is equal to the return type of the function.
  (all vr: VariableReference | all vd: VarDecl | (vr.referredVar = vd.declaredVar) implies vr.type = vd.type) &&
  (all vr: VariableReference | all fp: FormalParameter | (vr.referredVar = fp.declaredVar) implies vr.type = fp.type)
}

// Functions have a set of formal parameters.
fact {
  Function.formals = FormalParameter // all formal parameters belong to a function
}

// Actual parameters are mapped to formal parameters.
fact {
  all ce: CallExpr | ce.actuals[Expr] = ce.function.formals
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
  all v: Variable |
    (v in (VarDecl.declaredVar + FormalParameter.declaredVar)) && // at least once
    (v not in (VarDecl.declaredVar & FormalParameter.declaredVar)) // at most once
}

// A variable that has been declared can be assigned to using an assignment statement.
fact {
  all vd: VarDecl | all a: AssignStatement | p_assignsTo[a, vd] implies (a in p_statementsAfter[vd])
}

// Once the variable has been assigned to, it can be used in expressions in subsequent statements.
fact {
  all s: Statement | all v: s.exprs.reads | !p_isParameter[v] implies some a: AssignStatement | (v = a.assignedTo) && (s in p_statementsAfter[a])
}

// We do not allow dead variables (variables that are not parameters and are never read).
fact {
  all v: Variable | p_isDeclared[v] implies p_isRead[v]
}

// We do not allow dead assignments (assignments that are not followed by a read of the variable).
fact {
  all a: AssignStatement, v: a.assignedTo | some s: p_statementsAfter[a] | v in s.exprs.reads && (no s': (p_statementsAfter[a] - p_statementsAfter[s]) | v= s'.assignedTo)
}

// Parameters should never be assigned to.
fact {
  all v: Variable | p_isParameter[v] implies (!p_isAssigned[v])
}

// Variables (declared either by a VarDecl or as FormalParameter) are local to a function
fact {
  all disj f1, f2: Function | disj[f1.statements.exprs.reads, f2.(statements.exprs.reads + formals.declaredVar)]
}

// Expressions form trees, and nodes of expression trees are never shared, i.e. every node has a unique parent.
fact {
  (parent = ~children) && (no e: Expr | e in e.^children) && // parent/children relationship has no cycles
  ((Statement.exprs + Expr.children) = Expr) && // all expressions have a parent
  (no (Statement.exprs & Expr.children)) && (no (Statement.assignedValue & Statement.returnValue)) && // Every node has at most one parent.
  (children = actuals.FormalParameter)
}

// The usual typing rules apply to assignments, function calls and return statements.
fact {
  (supertype = ~subtypes) && (no t: Type | t in t.^subtypes) && // supertye/subtypes relationship has no cycles
  ((Function.returnType + VarDecl.type + FormalParameter.type + p_expressionTypes) = Type) && // all types are used
  (all a: AssignStatement | all vd: VarDecl | p_assignsTo[a, vd] implies p_subtypeOf[a.assignedValue.type, vd.type]) &&
  (all e: Expr, fp: FormalParameter | (e->fp in CallExpr.actuals) implies p_subtypeOf[e.type, fp.type]) &&
  (all f: Function | p_subtypeOf[f.returnStmt.returnValue.type, f.returnType])
}

/* --------------------------------------------------------------------------------
 * Functions (Static Model)
 * -------------------------------------------------------------------------------- */

// Returns the number of function calls (call expressions) in the program.
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
 * Predicates (Static Model)
 * -------------------------------------------------------------------------------- */

// true iff f contains a function call directly in its body.
pred p_containsCall [f: Function] {
  some p_statementsInFunction[f].exprs.*children :> CallExpr
}

// true iff v appears on the left side of an assignment anywhere in the program.
pred p_isAssigned [v: Variable] {
  v in AssignStatement.assignedTo
}

// true iff v appears in an expression anywhere in the program. Exclude writes.
pred p_isRead [v: Variable] {
  v in VariableReference.referredVar
}

// true iff v is declared through a variable declaration.
pred p_isDeclared [v: Variable] {
  v in VarDecl.declaredVar
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
  s.assignedTo = vd.declaredVar
}

/* --------------------------------------------------------------------------------
 * Additional Relations (Static Model)
 * -------------------------------------------------------------------------------- */

// Returns tuples of the form (caller, callee): (Function, Function), i.e. the function 'caller' calls the function 'calle' in its body.
fun functions: set Function -> Function {
  (statements.exprs.*children :> CallExpr).function
}

// Returns tuples of functions and their statements.
fun statements: set Function -> Statement {
  firstStmt.*successor
}

// Returns tuples of statements and their direct subexpressions.
fun exprs: set Statement -> Expr {
  assignedValue + returnValue
}

// Returns tuples of expressions and the variables they read.
fun reads: set Expr -> Variable {
  *children.referredVar
}
