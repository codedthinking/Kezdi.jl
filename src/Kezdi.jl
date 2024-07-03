"""
Kezdi.jl is a Julia package for data manipulation and analysis. It is inspired by Stata, but it is written in Julia, which makes it faster and more flexible. It is designed to be used in the Julia REPL, but it can also be used in Jupyter notebooks or in scripts.
"""
module Kezdi
export @generate, @replace, @egen, @collapse, @keep, @drop, @summarize, @regress, use, @use, @tabulate, rowcount, distinct, @count, @sort, @order, getdf, setdf, @list, @head, @tail, @names, @ephemeral, display_and_return

using Reexport
using Logging
using InteractiveUtils
using ReadStatTables

@reexport using FreqTables: freqtable
@reexport using FixedEffectModels
@reexport using Statistics
@reexport using CSV
@reexport using DataFrames
@reexport using StatsBase
import Base: count

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

end # module
