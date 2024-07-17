!!! warning "Kezdi.jl is in beta"
    `Kezdi.jl` is currently in beta. We have more than 300 unit tests and a large code coverage. [![Coverage](https://codecov.io/gh/codedthinking/Kezdi.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/codedthinking/Kezdi.jl) The package, however, is not guaranteed to be bug-free. If you encounter any issues, please report them as a [GitHub issue](https://github.com/codedthinking/Kezdi.jl/issues/new).

    If you would like to receive updates on the package, please star the repository on GitHub and sign up for [email notifications here](https://relentless-producer-1210.ck.page/62d7ebb237).

!!! warning "This is the developer documentation"
    You are currently reading the documentation for developers. This explains the internal working of Kezdi.jl. If you do not want to change or contribute to Kezdi.jl functionality, head over to the [end-user documentation]().

## Developer documentation
### How Kezdi.jl works: High-level overview
At its core, Kezdi.jl is a *transpiler*: it takes commands with Stata-like syntax entered by the user and translates them to regular Julia function calls to DataFrames and other modules. Most of the code deals with steps in this transpiling process:

1. scanning and parsing Julia expression to be evaluated as Kezdi.jl syntax
2. generating Julia code common for all commands, like subsetting dataframe rows whenever `@if` is used
3. generating Julia code specific to the command called

As an example, let us see how the following Kezdi.jl command becomes Julia code:
```julia
@replace distance = 5 @if distance < 0
```

The compiler will try to expand the `@replace` macro. It will hence call the macro `replace`, defined in `src/macros.jl`. The macro definition is almost identical for all Kezdi.jl macros:
```julia
macro replace(exprs...)
    :replace |> parse(exprs) |> rewrite
end
```
The function `parse`, defined in `src/parse.jl` consumes all the Julia tokens to the right of `@replace` and returns a `Command` struct with the command name, arguments, and the expression to be evaluated, including any options or `@if` clauses. In this case, we get
```julia
Kezdi.Command(:replace, (:(distance = 5),), :(distance < 5), ())
``` 

This `Command` is then passed onto the `rewrite` function, defined in `src/codegen.jl`. This function dispatches on the first argument of the `Command` struct and first calls the function `generate_command` (also defined in `src/codegen.jl`). This function returns a `GeneratedCommand`. (All structs are defined in `src/structs.jl`.) The `GeneratedCommand` struct contains the

1. name of the DataFrame with which the command was called
2. name of the DataFrame to operate on
    - This will be different from the first if there is an `@if` clause or a `by` option
3. a Julia `quote` block that will run before the command
    - This usually deals with error checking, subsetting rows and grouping the DataFrame
4. name of a function to be run after the command has finished
5. arguments and
6. options as parsed

This `GeneratedCommand` is then consumed by the `rewrite` function which implements the actual functionality of the command. In this case, the function does runtime error checking (like making sure that the column `distance` exists in the DataFrame), type checking and promotion and the actual replacement of values. The function returns a Julia `quote` block that will be evaluated by Julia in its next step of compilation (code lowering).

Removing `LineNumberNode`s for brevity, the final Julia code will look like this:
```julia
if !("distance" in names(getdf()))
    ArgumentError("Column \"distance\" does not exist in $(names(getdf()))") |> throw
else
    begin
        getdf() isa AbstractDataFrame || error("Kezdi.jl commands can only operate on a global DataFrame set by setdf()")
        local var"##361" = copy(getdf())
        local var"##362" = view(var"##361", falses(nrow(var"##361")) .| Missings.replace((var"##361").distance .< 5, false), :)
        begin
            function var"##364"(x)
                begin
                end
                x
            end
        end
    end
    eltype_RHS = if 5 isa AbstractVector
            eltype(5)
        else
            typeof(5)
        end
    eltype_LHS = eltype(var"##361"[.!(falses(nrow(var"##361")) .| Missings.replace((var"##361").distance .< 5, false)), "distance"])
    if eltype_RHS != eltype_LHS
        local var"##365" = Vector{promote_type(eltype_LHS, eltype_RHS)}(undef, nrow(var"##361"))
        var"##365"[falses(nrow(var"##361")) .| Missings.replace((var"##361").distance .< 5, false)] .= 5
        var"##365"[.!(falses(nrow(var"##361")) .| Missings.replace((var"##361").distance .< 5, false))] .= var"##361"[.!(falses(nrow(var"##361")) .| Missings.replace((var"##361").distance .< 5, false)), "distance"]
        var"##361"[!, "distance"] = var"##365"
    else
        var"##362"[!, "distance"] .= 5
    end
    (var"##361" |> var"##364") |> setdf
end
```

Note that macro hygene dictates the use of temporary variables like `var"##361"` and `var"##362"` to avoid name clashes with the user's code. This is a little hard to debug as a developer, but the generated code will typically not be seen by the end user.

## Style guide