# Elements that are not encodable in the UML class diagram

(The non-UML-encdoable element is listed first. An optional explanation is in parantheses.)

- Functions consist of a *linear sequence* of statements.
- Actual parameters are mapped to formal parameters. (This would be done by a semantic analyser).
- Return statement terminates the execution.
- A function may not contain unreachable statements.
- Recursion is not allowed.
- There is one main function that takes no parameters.
- All functions are transitively called from the main function.
- A variable has to be declared at least once. (We only modelled it has to be declared at most once)
- Variables must be declared in the same function before the first use such as the first assignment.
- Variables can only be used is expressions after they have been assigned to.
- We do not allow dead variables or dead assignments.
- There are no assignments to parameters.
- Typing rules for assignments, function calls and return statements.
