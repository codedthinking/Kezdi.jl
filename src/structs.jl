struct Node
    type::Union{Symbol, Type}
    content::Union{Expr, Symbol, AbstractString, Number, LineNumberNode, QuoteNode, Vector{Any}}
end

struct Command 
    command::Symbol
    df::Any
    arguments::Tuple
    condition::Union{Expr, Nothing, Bool}
    options::Tuple
end

using DataFrames
using Statistics
using StatsBase

struct Summarize
    name::Symbol
    N::Int
    sum_w::Float64
    mean::Float64
    Var::Float64
    sd::Float64
    skewness::Float64
    kurtosis::Float64
    sum::Float64
    min::Float64
    max::Float64
    p1::Float64
    p5::Float64
    p10::Float64
    p25::Float64
    p50::Float64
    p75::Float64
    p90::Float64
    p95::Float64
    p99::Float64
end

# if DataFrame is not explicitly defined, use the first argument
Command(command::Symbol, arguments::Tuple, condition, options) = Command(command, arguments[1], arguments[2:end], condition, options)