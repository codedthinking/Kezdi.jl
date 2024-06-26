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

struct GeneratedCommand
    df::Any
    local_copy::Symbol
    sdf::Symbol
    gdf::Symbol
    setup::Vector{Expr}
    teardown::Vector{Expr}
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

function Base.show(io::IO, s::Summarize)
    println(io, "Summarize ", s.name, ":")
    println(io, "  N = ", s.N)
    println(io, "  sum_w = ", s.sum_w)
    println(io, "  mean = ", s.mean)
    println(io, "  Var = ", s.Var)
    println(io, "  sd = ", s.sd)
    println(io, "  skewness = ", s.skewness)
    println(io, "  kurtosis = ", s.kurtosis)
    println(io, "  sum = ", s.sum)
    println(io, "  min = ", s.min)
    println(io, "  max = ", s.max)
    println(io, "  p1 = ", s.p1)
    println(io, "  p5 = ", s.p5)
    println(io, "  p10 = ", s.p10)
    println(io, "  p25 = ", s.p25)
    println(io, "  p50 = ", s.p50)
    println(io, "  p75 = ", s.p75)
    println(io, "  p90 = ", s.p90)
    println(io, "  p95 = ", s.p95)
    println(io, "  p99 = ", s.p99)
end

# if DataFrame is not explicitly defined, use the first argument
Command(command::Symbol, arguments::Tuple, condition, options) = Command(command, arguments[1], arguments[2:end], condition, options)