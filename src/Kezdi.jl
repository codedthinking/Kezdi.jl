module Kezdi
export @generate, @replace, @egen, @collapse, @keep, @drop, @summarize, @regress, use, @use, @tabulate, rowcount, distinct, @count

using Reexport
using Logging
using InteractiveUtils
using StatFiles

@reexport using FreqTables: freqtable
@reexport using FixedEffectModels
@reexport using Statistics
@reexport using CSV
@reexport using DataFrames
@reexport using StatsBase: mean
import Base: count

include("consts.jl")
include("structs.jl")
include("commands.jl")
include("macros.jl")
include("parse.jl")
include("codegen.jl")
include("rewrites.jl")

include("With.jl")
@reexport using .With: @with, @with!

end # module
