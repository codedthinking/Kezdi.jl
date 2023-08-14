module Kezdi
export @regress, @keep_if

using Reexport
@reexport using Tidier
@reexport using CSV
@reexport using DataFrames
@reexport using Distributions
@reexport using FixedEffectModels
@reexport using LinearAlgebra
@reexport using StatFiles

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

macro keep_if(df, expr)
	return esc(:(@filter($df, $expr)))
end

@doc """
Exports all names defined in the packages.

`@keep_if` macro keeps only rows of a DataFrame that satisfy a condition:
```
@keep_if df price > 0
```

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
The macros can also be used within a [chain](https://github.com/jkrumbiegel/Chain.jl):
```
@chain df begin
    @keep_if price > 0
    @regress price quantity fe(country)
end
"""

end # module
