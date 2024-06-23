struct Node
    type::Union{Symbol, Type}
    content::Union{Expr, Symbol, AbstractString, Number, LineNumberNode, QuoteNode, Vector{Any}}
end

struct Context 
    scalars::Vector{Symbol}
    flags::Set{Symbol}
end

Context() = Context(Symbol[], DEFAULT_FLAGS)
Base.in(s::Symbol, c::Context) = s in c.flags

struct Command 
    command::Symbol
    df::Any
    context::Context
    arguments::Tuple
    condition::Union{Expr, Nothing, Bool}
    options::Tuple
end

# if DataFrame is not explicitly defined, use the first argument
Command(command::Symbol, arguments::Tuple, condition, options) = Command(command, arguments[1], arguments[2:end], condition, options)
# if context is not explicitly defined, pass the default context
Command(command::Symbol, df, arguments::Tuple, condition, options) = Command(command, df, Context(), arguments, condition, options)