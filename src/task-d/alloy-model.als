/* TODO
 Simplify the model to BOOLEANLINEAR - done
 Add the model of executions - first version
 signature Execution - done
 signature Value - done
 functions - done
 generate instances (task E) - pending
 check multiplicities - done
 use functions - done
*/

// ---------- Instances for task E --------------------------------------------------- //


//A program that takes 2 arguments and computes AND
pred inst1{
  #MainFunction.formals = 2 &&
  all e: Execution, disj fp, fp': MainFunction.formals |
    (p_valbefore[e, MainFunction.firstStmt, fp.declaredVar] = True && p_valbefore[e, MainFunction.firstStmt, fp'.declaredVar] = True)
    implies (p_retval[e, MainFunction] = True)
    else (p_retval[e, MainFunction] = False)
}
run inst1

//A program that takes 2 arguments and computes NAND
pred inst2{
	#MainFunction.formals = 2 &&
	 all e: Execution, disj fp, fp': MainFunction.formals |
    (p_valbefore[e, MainFunction.firstStmt, fp.declaredVar] = True && p_valbefore[e, MainFunction.firstStmt, fp'.declaredVar] = True)
    implies (p_retval[e, MainFunction] = False)
    else (p_retval[e, MainFunction] = True)
}
run inst2 

//A program that takes 2 arguments, has at least one literal and one assignment and computes OR
pred inst3{
	#MainFunction.formals = 2 &&
	some Literal &&
	some AssignStatement &&
	all e: Execution, disj fp, fp': MainFunction.formals |
    (p_valbefore[e, MainFunction.firstStmt, fp.declaredVar] = False && p_valbefore[e, MainFunction.firstStmt, fp'.declaredVar] = False)
    implies (p_retval[e, MainFunction] = False)
    else (p_retval[e, MainFunction] = True)
} // NOT feasible
run inst3 

//A program that takes 2 arguments and computes XOR
pred inst4{
	#MainFunction.formals = 2 &&
	 all e: Execution, disj fp, fp': MainFunction.formals |
   		 (p_valbefore[e, MainFunction.firstStmt, fp.declaredVar] = False && p_valbefore[e, MainFunction.firstStmt, fp'.declaredVar] = False)
    implies (p_retval[e, MainFunction] = False)
    else (
		(p_valbefore[e, MainFunction.firstStmt, fp.declaredVar] = True && p_valbefore[e, MainFunction.firstStmt, fp'.declaredVar] = True)
    		implies (p_retval[e, MainFunction] = False)
		else(p_retval[e, MainFunction] = True)
	)
}
run inst4

/*A program that takes 2 arguments, has 3 functions and at least one assignment and computes NAND. Here, one function that is not the main
function should contain an And, and the other function that is not the main function should contain a Not.*/
pred inst5{
	#MainFunction.formals = 2 &&
	#Function = 3 &&
	some AssignStatement &&
	all e: Execution, disj fp, fp': MainFunction.formals |
    		(p_valbefore[e, MainFunction.firstStmt, fp.declaredVar] = True && p_valbefore[e, MainFunction.firstStmt, fp'.declaredVar] = True)
    implies (p_retval[e, MainFunction] = False)
    else (p_retval[e, MainFunction] = True) &&
	some disj f1, f2, f3: Function | (AndExpr in f1.statements.exprs && NotExpr in f2.statements.exprs && f3 = MainFunction)
} //NOT feasible
run inst5

// ---------- Dynamic Model of task D ---------------------------------------------- //

pred show {}
run show for 5

/* --------------------------------------------------------------------------------
 * Signatures
 * -------------------------------------------------------------------------------- */

sig Execution {
  inputs: FormalParameter set -> lone (True +False),
  varValue: Statement -> Variable set -> lone Value, // An execution reflects the value of each variable at each point in the program, i.e. before each statement in the program.
  exprValue: Expr set -> one Value, // An execution uniquely relates every expression in the program to a value from the set True, False, Undefined.
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
 * Facts (Dynamic Model)
 * -------------------------------------------------------------------------------- */

// Precondition that holds before the execution starts.
fact {
  all e: Execution | e.inputs.Value = MainFunction.formals
  all e: Execution, fp: FormalParameter | (fp in MainFunction.formals) implies (p_argval[e, MainFunction, fp] = e.inputs[fp]) else (no p_argval[e, MainFunction, fp])
  all e: Execution, vd: VarDecl | no e.varValue[MainFunction.firstStmt][vd.declaredVar]
}

// Invariants that need to hold after the execution terminates.
assert inv {
  all e: Execution, expr: Expr | p_val[e, expr] in (True + False)
  all e: Execution, v: Variable | p_valbefore[e, MainFunction.returnStmt, v] in (True + False)
}

fact {
  all e: Execution, a: AssignStatement |
    e.varValue[a.successor] = e.varValue[a] ++ a.assignedTo -> p_val[e, a.assignedValue]
}

fact {
  all e: Execution, vd: VarDecl |
    e.varValue[vd.successor] = e.varValue[vd] ++ vd.declaredVar -> Undefined
}

fact {
  all e: Execution, ce: CallExpr |
    (all a: Expr, fp: FormalParameter | (fp in ce.actuals[a]) implies (p_argval[e, ce.function, fp] = p_val[e, a])) &&
    (p_val[e, ce] = p_retval[e, ce.function])
}

fact {
  all e: Execution, ae: AndExpr |
    (p_val[e, ae.leftChild] = True && p_val[e, ae.rightChild] = True) implies (p_val[e, ae] = True) else (p_val[e, ae] = False)
}

fact {
  all e: Execution, ne: NotExpr |
    (p_val[e, ne.child] = True) implies (p_val[e, ne] = False) else (p_val[e, ne] = True)
}

fact {
  all e: Execution, vr: VariableReference |
    p_val[e, vr] = e.varValue[(exprs.*children).vr][vr.referredVar]
}

fact {
  all e: Execution, l: Literal |
    p_val[e, l] = l.value
}

/* --------------------------------------------------------------------------------
 * Functions (Dynamic Model)
 * -------------------------------------------------------------------------------- */

// Returns the value of p in execution e.
fun p_val [e: Execution, p: Expr]: Value {
  e.exprValue[p]
}

// Returns the return value of f in e.
fun p_retval [e: Execution, f: Function]: Value {
  p_val[e, f.returnStmt.returnValue]
}

// Returns the value of formal parameter p of funcion f in execution e.
fun p_argval [e: Execution, f: Function, p: FormalParameter]: Value {
  p_valbefore[e, f.firstStmt, p.declaredVar]
}

// Returns the number of Not-expressions.
fun p_numNot: Int {
  #NotExpr
}

// Returns the value of variable v before executing statement s in execution e.
fun p_valbefore [e: Execution, s: Statement, v: Variable]: Value {
  e.varValue[s][v]
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
