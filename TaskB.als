sig LINEARProgram{
	mainFunc: one mainFunction,
	funcs: some Function
}

sig Expr {
	parent: lone Expr
}

sig VariableReference extends Expr{}

sig Variable{}

sig Function{
	returnType: one Type,
	returnStat: one ReturnStatement,
	arguments: some FormalParameter
}

sig Literal extends Expr{}

sig Statement{
	follows: lone Statement,
	preceeds: lone Statement,
}

sig VarDecl extends Statement{
	var: one Variable
}

sig Type{
	parent: lone Type
}

sig FormalParameter{}

sig AssignStatement extends Statement{
	var: one VariableReference
}

sig ReturnStatement extends Statement{}{ no preceeds }

one sig MainFunction extends Function{}

sig CallExpression extends Expr{
	actualParameter: some Expr
}



fun p_numFunctionCalls[]: Int {}

fun p_expressionTypes[]: set Type {}

fun p_statementsInFunction[f:Function]: set Statement {}

fun p_statementsAfter[s: Statement]: set Statement {}
 
fun p_parameters[f:Function]: FormalParameter {}

fun p_subExprs[e:Expr]: set Expr {}


pred p_conainsCall[f:Function] {}

pred p_isAssigned[v:Variable] {}

pred p_isRead[v: Variable] {}

pred p_isDeclared[v: Variable] {}

pred p_isParameter[v: Variable] {}

pred p_subtypeOf[t1: Type, t2: Type] {}

pred p_assignsTo[s: Statement, vd: VarDecl] {}


