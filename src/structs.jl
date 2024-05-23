struct Node
    type::Union{Symbol, Type}
    content::Union{Expr, Symbol, Number, LineNumberNode, QuoteNode}
    level::Int64
    tree_position::Int64
end

struct Command 
    command::Symbol
    arguments::Tuple
    condition::Union{Expr, Nothing}
    options::Tuple
end
