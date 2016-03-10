# Elements that are not encodable in UML

*The non-UML-encdoable element is listed first. An optional explanation is in parantheses.)

- Variable has to be declared at least once. (We only modelled it has to be declared at most once)
- Mapping to formal parameters. (This is done internally)
- Return statement terminates execution.
- A function may not contain unreachable statements.
- No recursion.
- All functions are called transitively from the main function.
- Variables must be declared before the first use such as the first assignment.
- Variables can only be used is expressions after it they have been assigned.
- Dead assignments and dead variables.
- No assignments in parameters.
- Typing rules.
