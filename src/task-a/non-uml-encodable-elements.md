# Elements that are not encodable in the UML class diagram

(The non-UML-encodable element is listed first. An optional explanation is in parentheses.)

- The first statement has no predecessor.
- The return statement has no successor.
- Actual parameters are mapped to formal parameters. (This would be done by a semantic analyser).
- Return statement terminates the execution.
- A function may not contain unreachable statements.
- Recursion is not allowed.
- The children of the call expression are in parent-child relation with the actual parameters.
- There is one main function that takes no parameters.
- All functions are transitively called from the main function.
- A variable has to be declared at least once. (We only modelled it has to be declared at most once)
- Variables must be declared in the same function before the first use such as the first assignment.
- Variables can only be used is expressions after they have been assigned to.
- We do not allow dead variables or dead assignments.
- There are no assignments to parameters.
- Typing rules for assignments, function calls and return statements.
