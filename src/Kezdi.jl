module Kezdi
export @regress

using Reexport
@reexport using CSV
@reexport using Chain
@reexport using DataFrameMacros
@reexport using DataFrames
@reexport using Distributions
@reexport using FixedEffectModels
@reexport using LinearAlgebra
@reexport using StatFiles
@reexport using Statistics

macro regress(df, formula)
	esc(:(reg($df, @formula($formula))))
end

macro regress(df, y, xs...)
	@show terms
	formula = Expr(:call, :~,
		y,
		Expr(:call, :+, xs...)
	)
	esc(:(reg($df, @formula($formula))))
end

@doc """
Exports all names defined in the packages.

`@regress` macro defines new syntax for regressions:
```
@regress df price ~ 1 + quantity + fe(country)
```
and 
```
@regress df price quantity fe(country)
```
both evaluate to
```
reg(df, @formula(price ~ 1 + quantity + fe(country))
```
The macro can also be used within a [chain](https://github.com/jkrumbiegel/Chain.jl):
```
@chain df begin
    @regress price quantity fe(country)
end
```
"""

end # module
