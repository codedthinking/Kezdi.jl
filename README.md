# Kezdi.jl
An umbrella of Julia packages for data analysis, in loving memory of Gábor Kézdi.

Uses CSV, Chain, DataFrameMacros, DataFrames, Distributions, FixedEffectModels, LinearAlgebra, StatFiles, Statistics.

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
