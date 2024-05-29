"""
# Kezdi.jl
An umbrella of Julia packages for data analysis, with a focus on economics.

To install,
```julia
using Pkg
Pkg.add(url="https://github.com/codedthinking/Kezdi.jl.git")
```

Uses [Tidier](https://tidierorg.github.io/Tidier.jl/dev/), [CSV](https://csv.juliadata.org/stable/), [Chain](https://github.com/jkrumbiegel/Chain.jl), [DataFrameMacros](https://github.com/jkrumbiegel/DataFrameMacros.jl), [DataFrames](https://dataframes.juliadata.org/stable/), [Distributions](https://juliastats.org/Distributions.jl/stable/), [FixedEffectModels](https://github.com/FixedEffects/FixedEffectModels.jl), [LinearAlgebra](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/), [StatFiles](https://github.com/queryverse/StatFiles.jl), [Statistics](https://docs.julialang.org/en/v1/stdlib/Statistics/).

Exports all names defined in the packages.

## Example
```jldoctest
using Kezdi
using RDatasets

movies = dataset("ggplot2", "movies")

@chain movies begin
	@drop_if ismissing(Budget) || Budget == 0
	@generate ln_budget = log(Budget)
	@generate above_7 = Rating > 7.0
	@regress ln_budget above_7 fe(Year)
end

# output

terms = StatsModels.terms
                            FixedEffectModel                            
========================================================================
Number of obs:                 5181  Converged:                     true
dof (model):                      1  dof (residuals):               5087
R²:                           0.164  R² adjusted:                  0.149
F-statistic:                65.0919  P-value:                      0.000
R² within:                    0.013  Iterations:                       1
========================================================================
          Estimate  Std. Error    t-stat  Pr(>|t|)  Lower 95%  Upper 95%
────────────────────────────────────────────────────────────────────────
above_7  -0.653116   0.0809519  -8.06795    <1e-15  -0.811817  -0.494416
========================================================================
```

## Naming
Kezdi.jl is named in loving memory of [Gábor Kézdi](https://kezdigabor.life/).
"""
module Kezdi
export @regress, @keep_if, @drop_if, @keep, @drop, @generate, @replace, @egen

using Reexport
@reexport using CSV
@reexport using DataFrames

"""
	@regress(df, formula)

Runs a regression on a DataFrame using the FixedEffectModels package.

# Arguments
- `df`: A DataFrame.
- `formula`: A formula in the StatsModels.jl syntax (`y ~ 1 + x1 + x2`) or in Stata(R) syntax (`y x1 x2`).

# Examples
```jldoctest
julia> df = DataFrame(a = repeat('a':'e'), b = 1:5, c = 11:15);

julia> @regress df c b
terms = StatsModels.terms
                               FixedEffectModel                               
==============================================================================
Number of obs:                       5  Converged:                        true
dof (model):                         1  dof (residuals):                     2
R²:                              1.000  R² adjusted:                     1.000
F-statistic:                5.28188e29  P-value:                         0.000
==============================================================================
             Estimate   Std. Error      t-stat  Pr(>|t|)  Lower 95%  Upper 95%
──────────────────────────────────────────────────────────────────────────────
b                 1.0  1.37596e-15  7.26765e14    <1e-99        1.0        1.0
(Intercept)      10.0  4.56354e-15  2.19128e15    <1e-99       10.0       10.0
==============================================================================

julia> @chain df begin
       @regress c b
       end
terms = StatsModels.terms
                               FixedEffectModel                               
==============================================================================
Number of obs:                       5  Converged:                        true
dof (model):                         1  dof (residuals):                     2
R²:                              1.000  R² adjusted:                     1.000
F-statistic:                5.28188e29  P-value:                         0.000
==============================================================================
             Estimate   Std. Error      t-stat  Pr(>|t|)  Lower 95%  Upper 95%
──────────────────────────────────────────────────────────────────────────────
b                 1.0  1.37596e-15  7.26765e14    <1e-99        1.0        1.0
(Intercept)      10.0  4.56354e-15  2.19128e15    <1e-99       10.0       10.0
==============================================================================
```
"""
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

"""
	@keep_if(df, expr)

Keeps only rows of a DataFrame that satisfy a condition.

# Arguments
- `df`: A DataFrame.
- `expr`: transformation that produce a vector containing `true` or `false`.

# Examples
```jldoctest 
julia> df = DataFrame(a = repeat('a':'e'), b = 1:5, c = 11:15);

julia> @chain df begin
       @keep_if b >= mean(b)
       end
3×3 DataFrame
 Row │ a     b      c     
     │ Char  Int64  Int64 
─────┼────────────────────
   1 │ c         3     13
   2 │ d         4     14
   3 │ e         5     15

julia> @chain df begin
       @keep_if b >= 3 && c >= 14
       end
2×3 DataFrame
 Row │ a     b      c     
     │ Char  Int64  Int64 
─────┼────────────────────
   1 │ d         4     14
   2 │ e         5     15

julia> @chain df begin
       @keep_if b in (1, 3)
       end
2×3 DataFrame
 Row │ a     b      c     
     │ Char  Int64  Int64 
─────┼────────────────────
   1 │ a         1     11
   2 │ c         3     13
```
"""
macro keep_if(df, expr)
	return esc(:(@filter($df, $expr)))
end

"""
	@drop_if(df, expr)

Drops rows of a DataFrame that satisfy a condition.

# Arguments
- `df`: A DataFrame.
- `expr`: transformation that produce a vector containing `true` or `false`.

# Examples
```jldoctest 
julia> df = DataFrame(a = repeat('a':'e'), b = 1:5, c = 11:15);

julia> @chain df begin
       @drop_if b >= mean(b)
       end
2×3 DataFrame
 Row │ a     b      c     
     │ Char  Int64  Int64 
─────┼────────────────────
   1 │ a         1     11
   2 │ b         2     12
```
"""
macro drop_if(df, expr)
	return esc(:(@filter($df, !$expr)))
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

"""
	@keep(df, exprs...)

Keeps only columns of a DataFrame.

# Arguments
- `df`: A DataFrame.
- `exprs...`: column names.

# Examples
```jldoctest
julia> df = DataFrame(a = repeat('a':'e'), b = 1:5, c = 11:15);

julia> @chain df begin
       @keep a b
       end
5×2 DataFrame
 Row │ a     b     
     │ Char  Int64 
─────┼─────────────
   1 │ a         1
   2 │ b         2
   3 │ c         3
   4 │ d         4
   5 │ e         5
```
"""
macro keep(df, exprs...)
	return esc(:(@select($df, $(exprs...))))
end

"""
	@drop(df, exprs...)

Drops columns of a DataFrame.

# Arguments
- `df`: A DataFrame.
- `exprs...`: column names.

# Examples
```jldoctest
julia> df = DataFrame(a = repeat('a':'e'), b = 1:5, c = 11:15);

julia> @chain df begin
	@drop a b
	end
5×1 DataFrame
 Row │ c     
     │ Int64 
─────┼───────
   1 │    11
   2 │    12
   3 │    13
   4 │    14
   5 │    15
```
"""
macro drop(df, exprs...)
    negated_exprs = Cols(Not([:($expr) for expr in exprs]...))
    return esc(:(select($df, $negated_exprs)))
end

"""
	@replace(df, expr)

Replaces a column of a DataFrame. An alias for `@mutate`, does not check if the column already exists.

# Arguments
- `df`: A DataFrame.
- `expr`: transformation that produces a vector.

# Examples
```jldoctest
julia> df = DataFrame(a = repeat('a':'e'), b = 1:5, c = 11:15)
5×3 DataFrame
 Row │ a     b      c     
	 │ Char  Int64  Int64
─────┼────────────────────
   1 │ a         1     11
   2 │ b         2     12
   3 │ c         3     13
   4 │ d         4     14
   5 │ e         5     15

julia> @chain df begin
	@replace b = b + 1
	end
5×3 DataFrame
 Row │ a     b      c     
	 │ Char  Int64  Int64
─────┼────────────────────
   1 │ a         2     11
   2 │ b         3     12
   3 │ c         4     13
   4 │ d         5     14
   5 │ e         6     15
```
"""
macro replace(df, expr)
	return esc(:(@mutate($df, $expr)))
end

"""
	@generate(df, expr)

Generates a new column of a DataFrame. An alias for `@mutate`, does not check if the column already exists.

# Arguments
- `df`: A DataFrame.
- `expr`: transformation that produces a vector.

# Examples
```jldoctest
julia> df = DataFrame(a = repeat('a':'e'), b = 1:5, c = 11:15)
5×3 DataFrame
 Row │ a     b      c     
	 │ Char  Int64  Int64
─────┼────────────────────
   1 │ a         1     11
   2 │ b         2     12
   3 │ c         3     13
   4 │ d         4     14
   5 │ e         5     15

julia> @chain df begin
	@generate d = 2 * b
	end
5×4 DataFrame
 Row │ a     b      c      d     
	 │ Char  Int64  Int64  Int64
─────┼──────────────────────────
   1 │ a         1     11      2
   2 │ b         2     12      4
   3 │ c         3     13      6
   4 │ d         4     14      8
   5 │ e         5     15     10
```
"""
macro generate(df, expr)
	return esc(:(@mutate($df, $expr)))
end

"""
	@egen(df, expr)

Generates a new column of a DataFrame. An alias for [`@generate`](@ref), does not check if the column already exists.
"""
macro egen(df, expr)
	return esc(:(@mutate($df, $expr)))
end

end # module
