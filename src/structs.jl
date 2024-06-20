struct Node
    type::Union{Symbol, Type}
    content::Union{Expr, Symbol, Number, LineNumberNode, QuoteNode, Vector{Any}}
    level::Int64
    tree_position::Int64
end

struct Command 
    command::Symbol
    df::Any
    arguments::Tuple
    condition::Union{Expr, Nothing}
    options::Tuple
end

# if DataFrame is not explicitly defined, use the first argument
Command(command::Symbol, arguments::Tuple, condition, options) = Command(command, arguments[1], arguments[2:end], condition, options)