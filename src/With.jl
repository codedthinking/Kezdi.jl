module With
using ..Kezdi
export @with, @with!

"""
    @with df begin
        # do something with df
    end

The `@with` macro is a convenience macro that allows you to set the current data frame and perform operations on it in a single block. The first argument is the data frame to set as the current data frame, and the second argument is a block of code to execute. The data frame is set as the current data frame for the duration of the block, and then restored to its previous value after the block is executed.

The macro returns the value of the last expression in the block.
"""
macro with(initial_value, args...)
    block = flatten_to_single_block(initial_value, args...)
    rewrite_with_block(block)
end

"""
    @with! df begin
        # do something with df
    end

The `@with!` macro is a convenience macro that allows you to set the current data frame and perform operations on it in a single block. The first argument is the data frame to set as the current data frame, and the second argument is a block of code to execute. The data frame is set as the current data frame for the duration of the block, and then restored to its previous value after the block is executed.

The macro does not have a return value, it overwrites the data frame directly.
"""
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
    reconvert_docstrings!(block_expressions)

    # save current dataframe, activate the first expression, restore on exit
    previous_df = gensym()
    header = []
    body = []
    did_first = false
    for expr in block_expressions
        # the first non-LineNumberNode is the DataFrame to activate; everything
        # after it is the body run against that active DataFrame
        if !(did_first || expr isa LineNumberNode)
            did_first = true
            push!(header, :(local $previous_df = getdf()))
            push!(header, :(setdf($expr)))
            continue
        end
        push!(body, expr)
    end
    did_first || error("No expressions found in with block.")

    # try/finally guarantees the previous DataFrame is restored even if the
    # body throws. But try introduces a scope, and aside assignments like
    # `s = @summarize x` must stay visible after the block, so their values are
    # captured inside the try and re-bound in the enclosing scope afterwards.
    targets = assigned_names(body)
    captured = gensym()
    value = gensym()
    captures = [:(Base.@isdefined($t) ? (true, $t) : (false, nothing)) for t in targets]
    rebinds = [quote
            if $captured[$(i + 1)][1]
                $t = $captured[$(i + 1)][2]
            end
        end for (i, t) in enumerate(targets)]
    quote
        $(header...)
        local $captured = try
            $([:(local $t) for t in targets]...)
            $value = begin
                $(body...)
            end
            ($value, $(captures...))
        finally
            setdf($previous_df)
        end
        $(rebinds...)
        $captured[1]
    end |> esc
end

# Names assigned at the top level of a with block's body (`s = @summarize x`,
# `a, b = f()`), in order of first appearance.
function assigned_names(body)
    names = Symbol[]
    add!(x) = x isa Symbol && !(x in names) && push!(names, x)
    for expr in body
        expr isa Expr && expr.head === :(=) || continue
        lhs = expr.args[1]
        if lhs isa Symbol
            add!(lhs)
        elseif lhs isa Expr && lhs.head === :tuple
            foreach(add!, lhs.args)
        end
    end
    names
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
