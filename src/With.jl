module With
using ..Kezdi
export @with

is_aside(x) = false
function is_aside(x::Expr)::Bool
    if x.head == :(=)
        return is_aside(x.args[2])
    end
    return x.head == :macrocall && x.args[1] in Kezdi.SIDE_EFFECTS 
end


insert_first_arg(symbol::Symbol, firstarg; assignment = false) = Expr(:call, symbol, firstarg)
insert_first_arg(any, firstarg; assignment = false) = insertionerror(any)

function insertionerror(expr)
    error(
        """Can't insert a first argument into:
        $expr.

        First argument insertion works with expressions like these, where [Module.SubModule.] is optional:

        [Module.SubModule.]func
        [Module.SubModule.]func(args...)
        [Module.SubModule.]func(args...; kwargs...)
        [Module.SubModule.]@macro
        [Module.SubModule.]@macro(args...)
        @. [Module.SubModule.]func
        """
    )
end

is_moduled_symbol(x) = false
function is_moduled_symbol(e::Expr)
    e.head == :. &&
        length(e.args) == 2 &&
        (e.args[1] isa Symbol || is_moduled_symbol(e.args[1])) &&
        e.args[2] isa QuoteNode &&
        e.args[2].value isa Symbol
end

function insert_first_arg(e::Expr, firstarg; assignment = false)
    head = e.head
    args = e.args
    # variable = ...
    # set assignment = true and rerun with right hand side
    if !assignment && head == :(=) && length(args) == 2
        if !(args[1] isa Symbol)
            error("You can only use assignment syntax with a Symbol as a variable name, not $(args[1]).")
        end
        variable = args[1]
        righthandside = insert_first_arg(args[2], firstarg; assignment = true)
        :($variable = $righthandside)
    # Module.SubModule.symbol
    elseif is_moduled_symbol(e)
        Expr(:call, e, firstarg)

    # f(args...) --> f(firstarg, args...)
    elseif head == :call && length(args) > 0
        if length(args) ≥ 2 && Meta.isexpr(args[2], :parameters)
            Expr(head, args[1:2]..., firstarg, args[3:end]...)
        elseif args[1] in [:env, :scalars]
            # does not have to insert first argument into $e
            Expr(head, args...)
        else
            Expr(head, args[1], firstarg, args[2:end]...)
        end

    # f.(args...) --> f.(firstarg, args...)
    elseif head == :. &&
            length(args) > 1 &&
            args[1] isa Symbol &&
            args[2] isa Expr &&
            args[2].head == :tuple

        Expr(head, args[1], Expr(args[2].head, firstarg, args[2].args...))

    # @. [Module.SubModule.]somesymbol --> somesymbol.(firstarg)
    elseif head == :macrocall &&
            length(args) == 3 &&
            args[1] == Symbol("@__dot__") &&
            args[2] isa LineNumberNode &&
            (is_moduled_symbol(args[3]) || args[3] isa Symbol)

        Expr(:., args[3], Expr(:tuple, firstarg))

    # @macro(args...) --> @macro(firstarg, args...)
    elseif head == :macrocall &&
        (is_moduled_symbol(args[1]) || args[1] isa Symbol) &&
        args[2] isa LineNumberNode
        if args[1] == Symbol("@__dot__")
            error("You can only use the @. macro and automatic first argument insertion if what follows is of the form `[Module.SubModule.]func`")
        end

        if length(args) >= 3 && args[3] isa Expr && args[3].head == :parameters
            # macros can have keyword arguments after ; as well
            Expr(head, args[1], args[2], args[3], firstarg, args[4:end]...)
        else
            Expr(head, args[1], args[2], firstarg, args[3:end]...)
        end

    else
        insertionerror(e)
    end
end

function rewrite(expr)
    is_aside(expr) ? :($display($expr)) : expr
end

rewrite(l::LineNumberNode) = l

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

    # save current dataframe
    previous_df = gensym()
    rewritten_exprs = []

    did_first = false
    for expr in block_expressions
        # could be an expression first or a LineNumberNode, so a bit convoluted
        # we just do the firstvar transformation for the first non LineNumberNode
        # we encounter
        if !(did_first || expr isa LineNumberNode)
            did_first = true
            push!(rewritten_exprs, :(local $previous_df = getdf()))
            push!(rewritten_exprs, :(setdf!($expr)))
            continue
        end
        
        rewritten = rewrite(expr)
        push!(rewritten_exprs, rewritten)
    end
    teardown = :(x -> begin
        setdf!($previous_df)
        x
    end)
    result = Expr(:block, rewritten_exprs...)

    :($(esc(result)) |> $(esc(teardown)))
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
