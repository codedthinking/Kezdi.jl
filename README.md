# Kezdi.jl
An umbrella of Julia packages for data analysis, in loving memory of [Gábor Kézdi](https://kezdigabor.life/).

To install,
```julia
using Pkg
Pkg.add(url="https://github.com/codedthinking/Kezdi.jl.git")
```

Uses [CSV](https://csv.juliadata.org/stable/), [Chain](https://github.com/jkrumbiegel/Chain.jl), [DataFrameMacros](https://github.com/jkrumbiegel/DataFrameMacros.jl), [DataFrames](https://dataframes.juliadata.org/stable/), [Distributions](https://juliastats.org/Distributions.jl/stable/), [FixedEffectModels](https://github.com/FixedEffects/FixedEffectModels.jl), [LinearAlgebra](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/), [StatFiles](https://github.com/queryverse/StatFiles.jl), [Statistics](https://docs.julialang.org/en/v1/stdlib/Statistics/).

Exports all names defined in the packages.

`@regress` macro defines new syntax for regressions:
```
using Kezdi
df = DataFrame(price=..., quantity=..., country=...)
@regress df price ~ 1 + quantity + fe(country)
```
and 
```
using Kezdi
df = DataFrame(price=..., quantity=..., country=...)
@regress df price quantity fe(country)
```
both evaluate to
```
using Kezdi
df = DataFrame(price=..., quantity=..., country=...)
reg(df, @formula(price ~ 1 + quantity + fe(country))
```
The macro can also be used within a [chain](https://github.com/jkrumbiegel/Chain.jl) and pipe:
```
@chain df begin
    @regress price quantity fe(country)
end
```
