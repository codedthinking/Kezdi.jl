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
@reexport using DataFrames

include("transpiler.jl")
include("codegen.jl")

end # module
