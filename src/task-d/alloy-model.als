/* TODO
 Simplify the model to BOOLEANLINEAR - done
 Add the model of executions - implementation pending
 signature Execution - implementation pending
 signature Value - done
 functions - implementation pending
 check multiplicities
 use functions
*/

open util/ordering[Step]

// ---------- Instances for task E --------------------------------------------------- //

// ---------- Dynamic Model of task D ---------------------------------------------- //

pred show {}
run show for 5

/* --------------------------------------------------------------------------------
 * Signatures
 * -------------------------------------------------------------------------------- */

sig Execution {
  steps: set Step,
  inputs: Value lone -> lone FormalParameter,
}

fact {
  all e: Execution | e.inputs[Value] = MainFunction.formals
}

sig Step {
  varValue: Variable -> Value, // An execution reflects the value of each variable at each point in the program.
  exprValue: Expr -> Value, // An execution uniquely relates every expression in the program to a value from the set True, False, Undefined.
}

abstract sig Value {}

one sig True, False, Undefined extends Value {}

sig Function {
  firstStmt: disj one Statement,
  returnStmt: disj one ReturnStatement, // Each function execution must be terminated by a return statement.
  formals: disj set FormalParameter, // Functions have a set (may be zero) of formal parameters.
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
}

sig FormalParameter {
  declaredVar: disj one Variable,
}

abstract sig Expr {
  parent: lone Expr,
  children: disj set Expr, // may have zero direct children
}

sig CallExpr extends Expr {
  function: disj one Function, // A function can be called in a corresponding call expression. Every function is called at most once.
  actuals: Expr lone -> lone FormalParameter, // A call expression is assiociated with a set of expressions that serve as actual parameters and are mapped to formal parameters.
}

sig Literal extends Expr {
  value: one (True + False) // Every literal is associated with a fixed value - either True or False.
}

sig VariableReference extends Expr {
  referredVar: one Variable, // reads value from the variable
}

// Extend your model by expressions that model the binary operations And.
sig AndExpr extends Expr {
  leftChild: one Expr,
  rightChild: one Expr,
}

// Extend your model by expressions that model the unary operation Not.
sig NotExpr extends Expr {
  child: one Expr,
}

sig Variable {}

/* --------------------------------------------------------------------------------
 * Facts/Traces (Dynamic Model)
 * -------------------------------------------------------------------------------- */

pred init [s: Step] {
  no s.varValue &&
  all e: Expr | s.exprValue[e] = Undefined
}

pred final [s: Step] {
  all v: Variable | s.varValue[v] in (True + False)
  all e: Expr | s.exprValue[e] in (True + False)
}

pred t_assignStmt [s, s': Step, a: AssignStatement] {
  s.exprValue[a.assignedValue] != Undefined &&
  s'.exprValue = s.exprValue &&
  s'.varValue = s.varValue ++ a.assignedTo -> s.exprValue[a.assignedValue]
}

pred t_varDecl [s, s': Step, vd: VarDecl] {
  no s.varValue[vd.declaredVar] &&
  s'.exprValue = s.exprValue &&
  s'.varValue = s.varValue ++ vd.declaredVar -> Undefined
}

pred t_returnStmt [s, s': Step, rs: ReturnStatement] {
  s.exprValue[rs.returnValue] != Undefined &&
  s'.exprValue = s.exprValue ++ function.returnStmt.rs -> s.exprValue[rs.returnValue] &&
  s'.varValue = s.varValue
}

pred t_callExpr [s, s': Step, ce: CallExpr] {
  all e: ce.actuals.FormalParameter | s.exprValue[e] != Undefined &&
  s'.exprValue = s.exprValue &&
  all v: Variable, e: Expr | (v in ce.actuals[e].declaredVar) implies (s'.varValue[v] = s.exprValue[e]) else (s'.varValue = s.varValue)
}

pred t_andExpr [s, s': Step, ae: AndExpr] {
  s.exprValue[ae.leftChild] != Undefined &&
  s.exprValue[ae.rightChild] != Undefined &&
  (s.exprValue[ae.leftChild] = True && s.exprValue[ae.rightChild] = True) implies (s'.exprValue = s.exprValue ++ ae -> True) else (s'.exprValue = s.exprValue ++ ae -> False) &&
  s'.varValue = s.varValue
}

pred t_notExpr [s, s': Step, ne: NotExpr] {
  s.exprValue[ne.child] != Undefined &&
  (s.exprValue[ne.child] = True) implies (s'.exprValue = s.exprValue ++ ne -> False) else (s'.exprValue = s.exprValue ++ ne -> True) &&
  s'.varValue = s.varValue
}

pred t_varRef [s, s': Step, vr: VariableReference] {
  s'.exprValue = s.exprValue ++ vr -> s.varValue[vr.referredVar] &&
  s'.varValue = s.varValue
}

pred t_literal [s, s': Step, l: Literal] {
  s'.exprValue = s.exprValue ++ l -> l.value &&
  s'.varValue = s.varValue
}

fact traces {
  init[first] &&
  all s: Step - last {
    (some a: AssignStatement | t_assignStmt[s, s.next, a]) or
    (some vd: VarDecl | t_varDecl[s, s.next, vd]) or
    (some rs: ReturnStatement | t_returnStmt[s, s.next, rs]) or
    (some ce: CallExpr | t_callExpr[s, s.next, ce]) or
    (some ae: AndExpr | t_andExpr[s, s.next, ae]) or
    (some ne: NotExpr | t_notExpr[s, s.next, ne]) or
    (some vr: VariableReference | t_varRef[s, s.next, vr]) or
    (some l: Literal | t_literal[s, s.next, l])
  }
  final[last]
}

/* --------------------------------------------------------------------------------
 * Functions (Dynamic Model)
 * -------------------------------------------------------------------------------- */

// Returns the value of p in execution e.
fun p_val [e: Execution, p: Expr]: Value {
  True // TODO
}

// Returns the return value of f in e.
fun p_retval [e: Execution, f: Function]: Value {
  True // TODO
}

// Returns the value of formal parameter p in execution e.
fun p_argval [e: Execution, f: Function, p: FormalParameter]: Value {
  True // TODO
}

// Returns the number of Not-expressions.
fun p_numNot: Int {
  #NotExpr
}

// Returns the value of variable v before executing statement s in execution e.
fun p_valbefore [e: Execution, s: Statement, v: Variable]: Value {
  True // TODO
}

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

// There is one main function from which all other functions are transitively called.
fact {
  Function in MainFunction.*functions
}

// Variables are declared exactly once, either in a corresponding declaration statement or as function parameter.
fact {
  all v: Variable | p_isDeclared[v]
}

// A variable that has been declared can be assigned to using an assignment statement.
fact {
  all vd: VarDecl | all a: AssignStatement | p_assignsTo[a, vd] implies (a in p_statementsAfter[vd])
}

// Once the variable has been assigned to, it can be used in expressions in subsequent statements.
fact {
  all s: Statement | all v: s.exprs.reads | !p_isParameter[v] implies some a: AssignStatement | (v = a.assignedTo) && (s in p_statementsAfter[a])
}

// We do not allow dead variables (variables that are never read).
fact {
  all v: Variable | p_isRead[v]
}

// We do not allow dead assignments (assignments that are not followed by a read of the variable).
fact {
//  all a: AssignStatement | a.assignedTo in p_statementsAfter[a].exprs.reads // assignment is followed by any read of the variable, not necessary the assigned value
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
  (no (Statement.exprs & Expr.children)) && (no (Statement.assignedValue & Statement.returnValue)) && // parents are unique
  (children = actuals.FormalParameter + leftChild + rightChild + child) &&
  (all ae: AndExpr | ae.leftChild != ae.rightChild)
}

/* --------------------------------------------------------------------------------
 * Functions (Static Model)
 * -------------------------------------------------------------------------------- */

// Returns the number of function calls (call expressions) in the program.
fun p_numFunctionCalls: Int {
  #CallExpr
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

// true iff v is declared exactly once.
pred p_isDeclared [v: Variable] {
  (v in (VarDecl.declaredVar + FormalParameter.declaredVar)) && // at least once
  (v not in (VarDecl.declaredVar & FormalParameter.declaredVar)) // at most once
}

// true iff v is declared as a parameter.
pred p_isParameter [v: Variable] {
  v in FormalParameter.declaredVar
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
