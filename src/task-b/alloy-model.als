sig LINEARProgram {
	mainFunc: one mainFunction,
	funcs: some Function
}

sig Expr {
	parent: lone Expr,
	children: some Expr,
} {parent = ~children}

sig VariableReference extends Expr {}

sig Variable {}

sig Function {
	returnType: one Type,
	firstStmt: one Statement,
	returnStmt: one ReturnStatement,
	formals: some FormalParameter
}

sig Literal extends Expr {}

sig Statement {
	follows: lone Statement,
	preceeds: lone Statement
} {follows = ~preceeds}

sig VarDecl extends Statement {
	var: one Variable
}

sig Type {
	parent: lone Type
}

sig FormalParameter {}

sig AssignStatement extends Statement {
	left: one VariableReference,
	right: one Expr,
} {p_subTypeOf[left.Type, right.Type]}

sig ReturnStatement extends Statement {

} {no preceeds}

one sig MainFunction extends Function {}

sig CallExpression extends Expr {
	actuals: some Expr
}

/*
 * Functions and predicates below express
 * "what I want them to do"
 * and probably do not work just yet
 * - @limenet
 */

fun p_numFunctionCalls[]: Int {}

fun p_expressionTypes[]: set Type {}

fun p_statementsInFunction[f: Function]: set Statement {}

fun p_statementsAfter[s: Statement]: set Statement {}

fun p_parameters[f: Function]: FormalParameter {}

fun p_subExprs[e: Expr]: set Expr {}


pred p_containsCall[f: Function] {}

pred p_isAssigned[v: Variable] {
    v in one AssignStatement.left
}

pred p_isRead[v: Variable] {
    v in some VariableReference
}

pred p_isDeclared[v: Variable] {
    v in one VarDecl
}

pred p_isParameter[v: Variable] {
    v in Function.formalParams
}

pred p_subtypeOf[t1: Type, t2: Type] {
    t1.parent = t2
}

pred p_assignsTo[s: Statement, vd: VarDecl] {}


