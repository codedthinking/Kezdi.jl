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
            push!(rewritten_exprs, :(setdf($expr)))
            continue
        end
        
        push!(rewritten_exprs, expr)
    end
    teardown = :(x -> begin
        setdf($previous_df)
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
