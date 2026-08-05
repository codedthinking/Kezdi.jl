"""
Kezdi.jl is a Julia package for data manipulation and analysis. It is inspired by Stata, but it is written in Julia, which makes it faster and more flexible. It is designed to be used in the Julia REPL, but it can also be used in Jupyter notebooks or in scripts.
"""
module Kezdi

export @generate, @replace, @egen, @collapse, @keep, @drop, @summarize, @regress, @use, @tabulate, @count, @sort, @order, @list, @head, @tail, @names, @rename, @clear, @describe, @mvencode, @save, @append, @reshape

export getdf, setdf, display_and_return, keep_only_values, rowcount, distinct, cond, mvreplace, append, anymissing, apply_function

using Reexport
using Missings
using ReadStatTables
using Crayons

@reexport using FreqTables: freqtable
@reexport using FixedEffectModels
@reexport using Statistics
@reexport using CSV
@reexport using DataFrames
@reexport using StatsBase
@reexport using Dates

include("consts.jl")
include("structs.jl")
include("functions.jl")
include("macros.jl")
include("parse.jl")
include("codegen.jl")
include("commands.jl")
include("side_effects.jl")

include("With.jl")
@reexport using .With: @with, @with!

include("precompile.jl")

# Non-exported but user-facing API (Julia 1.11+ `public`). Parsed via eval so
# this file still parses on 1.10, where `public` is not a keyword. Placed after
# all includes so every referenced name is defined.
@static if VERSION >= v"1.11"
    eval(Meta.parse("public use, save, summarize, tabulate, prompt"))
end

end # module
