module With
export @with, @with!
using ..Kezdi

is_aside(x) = false
function is_aside(x::Expr)::Bool
    if x.head == :(=)
        return is_aside(x.args[2])
    end
    return x.head == :macrocall && Symbol(String(x.args[1])[2:end]) in Kezdi.SIDE_EFFECTS 
end


function call_with_context(e::Expr, firstarg; assignment = false)
    head = e.head
    args = e.args
    # set assignment = true and rerun with right hand side
    if !assignment && head == :(=) && length(args) == 2
        if !(args[1] isa Symbol)
            error("You can only use assignment syntax with a Symbol as a variable name, not $(args[1]).")
        end
        variable = args[1]
        righthandside = call_with_context(args[2], firstarg; assignment = true)
        return :($variable = $righthandside)
    end
    :(Kezdi.ScopedValues.@with Kezdi.runtime_context => Kezdi.RuntimeContext($firstarg) $e)
end

function rewrite(expr, replacement)
    aside = is_aside(expr)
    new_expr = call_with_context(expr, replacement)
    replacement = gensym()
    new_expr = :(local $replacement = $new_expr)

    (new_expr, replacement, aside)
end

rewrite(l::LineNumberNode, replacement) = (l, replacement, true)

function rewrite_with_block(firstpart, block)
    pushfirst!(block.args, firstpart)
    rewrite_with_block(block)
end

"""
    @with(expr, exprs...)

Rewrites a series of expressions into a with, where the result of one expression
is inserted into the next expression following certain rules.

**Rule 1**

Any `expr` that is a `begin ... end` block is flattened.
For example, these two pseudocodes are equivalent:

```julia
@with a b c d e f

@with a begin
    b
    c
    d
end e f
```

**Rule 2**

Any expression but the first (in the flattened representation) will have the preceding result
inserted as its first argument, unless at least one underscore `_` is present.
In that case, all underscores will be replaced with the preceding result.

If the expression is a symbol, the symbol is treated equivalently to a function call.

For example, the following code block

```julia
@with begin
    x
    f()
    @g()
    h
    @i
    j(123, _)
    k(_, 123, _)
end
```

is equivalent to

```julia
begin
    local temp1 = f(x)
    local temp2 = @g(temp1)
    local temp3 = h(temp2)
    local temp4 = @i(temp3)
    local temp5 = j(123, temp4)
    local temp6 = k(temp5, 123, temp5)
end
```

**Rule 3**

An expression that begins with `@aside` does not pass its result on to the following expression.
Instead, the result of the previous expression will be passed on.
This is meant for inspecting the state of the with.
The expression within `@aside` will not get the previous result auto-inserted, you can use
underscores to reference it.

```julia
@with begin
    [1, 2, 3]
    filter(isodd, _)
    @aside @info "There are \$(length(_)) elements after filtering"
    sum
end
```

**Rule 4**

It is allowed to start an expression with a variable assignment.
In this case, the usual insertion rules apply to the right-hand side of that assignment.
This can be used to store intermediate results.

```julia
@with begin
    [1, 2, 3]
    filtered = filter(isodd, _)
    sum
end

filtered == [1, 3]
```

**Rule 5**

The `@.` macro may be used with a symbol to broadcast that function over the preceding result.

```julia
@with begin
    [1, 2, 3]
    @. sqrt
end
```

is equivalent to

```julia
@with begin
    [1, 2, 3]
    sqrt.(_)
end
```

"""
macro with(initial_value, args...)
    block = flatten_to_single_block(initial_value, args...)
    rewrite_with_block(block)
end


macro with!(initial_value, args...)
    block = flatten_to_single_block(initial_value, args...)
    result = rewrite_with_block(block)
    :($(esc(initial_value)) = $(result))
end

function flatten_to_single_block(args...)
    blockargs = []
    for arg in args
        if arg isa Expr && arg.head === :block
            append!(blockargs, arg.args)
        else
            push!(blockargs, arg)
        end
    end
    Expr(:block, blockargs...)
end

function rewrite_with_block(block)
    block_expressions = block.args
    isempty(block_expressions) || 
        (length(block_expressions) == 1 && block_expressions[] isa LineNumberNode) &&
        error("No expressions found in with block.")

    reconvert_docstrings!(block_expressions)

    local_value = gensym()
    replaced_value = local_value
    current_df = local_value
    rewritten_exprs = []

    did_first = false
    for expr in block_expressions
        # could be an expression first or a LineNumberNode, so a bit convoluted
        # we just do the local_context transformation for the first non LineNumberNode
        # we encounter
        if !(did_first || expr isa LineNumberNode)
            expr = :(local $local_value = $expr)
            did_first = true
            push!(rewritten_exprs, expr)
            continue
        end
        
        rewritten, replaced_value, aside = rewrite(expr, current_df)
        push!(rewritten_exprs, rewritten)
        if !aside
            push!(rewritten_exprs, :(local $current_df = $replaced_value))
        end
    end
    
    result = Expr(:block, rewritten_exprs..., replaced_value)

    :($(esc(result)))
end

# if a line in a with is a string, it can be parsed as a docstring
# for whatever is on the following line. because this is unexpected behavior
# for most users, we convert all docstrings back to separate lines.
function reconvert_docstrings!(args::Vector)
    docstring_indices = findall(args) do arg
        (arg isa Expr
            && arg.head == :macrocall
            && length(arg.args) == 4
            && arg.args[1] == GlobalRef(Core, Symbol("@doc")))
    end
    # replace docstrings from back to front because this leaves the earlier indices intact
    for i in reverse(docstring_indices)
        e = args[i]
        str = e.args[3]
        nextline = e.args[4]
        splice!(args, i:i, [str, nextline])
    end
    args
end

end