# Elements that are not encodable in the UML class diagram

- The first statement has no predecessor.
- The return statement has no successor.
- Actual parameters are mapped to the formal parameters of the function our expression calls.
- A return statement terminates the execution of the function body.
- A function may not contain unreachable statements.
- Recursion is not allowed.
- The call expressions are in parent-child relation with the actual parameters.
- There is one main function that takes no parameters.
- All functions are transitively called from the main function.
- A variable has to be declared at least once. (We only modelled it has to be declared at most once, but we want to say that variables are declared exactly once.)
- Variables must be declared in the same function before the first use such as the first assignment.
- Variables can only be used is expressions after they have been assigned to.
- We do not allow dead variables or dead assignments.
- There are no assignments to parameters.
- Typing rules for assignments, function calls and return statements.
