# Kezdi.jl
An umbrella of Julia packages for data analysis, in loving memory of [Gábor Kézdi](https://kezdigabor.life/).

To install,
```julia
using Pkg
Pkg.add(url="https://github.com/codedthinking/Kezdi.jl.git")
```

Uses [Tidier](https://tidierorg.github.io/Tidier.jl/dev/), [CSV](https://csv.juliadata.org/stable/), [Chain](https://github.com/jkrumbiegel/Chain.jl), [DataFrameMacros](https://github.com/jkrumbiegel/DataFrameMacros.jl), [DataFrames](https://dataframes.juliadata.org/stable/), [Distributions](https://juliastats.org/Distributions.jl/stable/), [FixedEffectModels](https://github.com/FixedEffects/FixedEffectModels.jl), [LinearAlgebra](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/), [StatFiles](https://github.com/queryverse/StatFiles.jl), [Statistics](https://docs.julialang.org/en/v1/stdlib/Statistics/).

Exports all names defined in the packages.

`@keep_if` macro keeps only rows of a DataFrame that satisfy a condition:
```
@keep_if df price > 0
```

`@regress` macro defines new syntax for regressions:
```julia
using Kezdi
df = DataFrame(price=..., quantity=..., country=...)
@regress df price ~ 1 + quantity + fe(country)
```
and 
```julia
using Kezdi
df = DataFrame(price=..., quantity=..., country=...)
@regress df price quantity fe(country)
```
both evaluate to
```julia
using Kezdi
df = DataFrame(price=..., quantity=..., country=...)
reg(df, @formula(price ~ 1 + quantity + fe(country))
```
The macros can also be used within a [chain](https://github.com/jkrumbiegel/Chain.jl):
```julia
@chain df begin
    @keep_if price > 0
    @regress price quantity fe(country)
end
```
