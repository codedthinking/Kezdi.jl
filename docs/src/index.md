```@meta
CurrentModule = Kezdi
```

# Kezdi.jl Documentation
Kezdi.jl is a Julia package that provides a Stata-like interface for data manipulation and analysis. It is designed to be easy to use for Stata users who are transitioning to Julia.[^stata] 

It imports and reexports CSV, DataFrames, FixedEffectModels, FreqTables, ReadStatTables, Statistics, and StatsBase. 

## Getting started
### Installation
`Kezdi.jl` is currently in beta. To install the package, run the following command in Julia's REPL:

```julia
using Pkg; Pkg.add(url="https://github.com/codedthinking/Kezdi.jl")
```

Every Kezdi.jl command is a macro that begins with `@`. These commands operate on a global `DataFrame` that is set using the `setdf` function. 

### Example
```julia
using Kezdi
using RDatasets

setdf(dataset("datasets", "mtcars"))

@rename HP Horsepower
@rename Disp Displacement
@rename WT Weight
@rename Cyl Cylinders

@tabulate Gear
@keep @if Gear == 4
@keep MPG Horsepower Weight Displacement Cylinders
@summarize MPG
@regress log(MPG) log(Horsepower) log(Weight) log(Displacement) fe(Cylinders), robust 
```

<script async data-uid="62d7ebb237" src="https://relentless-producer-1210.ck.page/62d7ebb237/index.js"></script>

## Benefits of using Kezdi.jl
### Free and open-source
### Speed

| Command      | Stata | Julia 1st run | Julia 2nd run | Speedup |
| ------------ | ----- | ------------- | ------------- | ------- |
| `@egen`      | 4.90s | 1.60s         | 0.41s         | 10x     |
| `@collapse`  | 0.92s | 0.18s         | 0.13s         | 8x      |
| `@tabulate`  | 2.14s | 0.46s         | 0.10s         | 20x     |
| `@summarize` | 10.40s | 0.58s         | 0.37s         | 28x     |
| `@regress`   | 0.89s | 1.93s         | 0.16s         | 6x      |

### Use any Julia function
```julia
@generate logHP = log(Horsepower)
```

### Easily extendable with user-defined functions
The function can operate on individual elements,
```julia
get_make(text) = split(text, " ")[1]
@generate Make = get_make(Model)
```
or on the entire column:
```julia
function geometric_mean(x)
    n = length(x)
    return exp(sum(log.(x)) / n)
end
@collapse geom_NPG = geometric_mean(MPG), by(Cylinders)
```

## Commands

### Setting and inspecting the global DataFrame
```@docs
setdf
```

```@docs
getdf
```

```@docs
@names
```

```@docs
@list
```

```@docs
@head
```

```@docs
@tail
```

### Filtering columns and rows
```@docs
@keep
```

```@docs
@drop
```

### Modifying the data
```@docs
@rename
```

```@docs
@generate
```

```@docs
@replace
```

```@docs
@egen
```

```@docs
@collapse
```

```@docs
@sort
```


### Summarizing and analyzing data
```@docs
@count
```

```@docs
@tabulate
```

```@docs
@summarize
```

```@docs
@regress
```

## Use on another DataFrame
```@docs
@with
```

## Gotchas for Julia users
### Everything is a macro
### Comma is used for options
### Automatic variable name substitution
### Automatic vectorization
### Handling missing values

## Gotchas for Stata users
### All commands begin with `@`
### `@collapse` has same syntax as `@egen`

## Convenience function
```@docs
distinct
```


## Acknowledgements
[^stata]: Stata is a registered trademark of StataCorp LLC. Kezdi.jl is not affiliated with StataCorp LLC.

The package is built on top of [DataFrames.jl](https://dataframes.juliadata.org/stable/), [FreqTables.jl](https://github.com/nalimilan/FreqTables.jl) and [FixedEffectModels.jl](https://github.com/FixedEffects/FixedEffectModels.jl). 