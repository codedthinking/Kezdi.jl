# Kezdi.jl Documentation

```@docs
Kezdi
```

## Getting started
### Installation
```julia
using Pkg; Pkg.add("https://github.com/codedthinking/Kezdi.jl#0.4-beta")
```

### Example
```julia
using Kezdi
df = CSV.read("data.csv", DataFrame)

@with df 
```

<script async data-uid="62d7ebb237" src="https://relentless-producer-1210.ck.page/62d7ebb237/index.js"></script>

## Benefits of using Kezdi.jl
### Speed

| Command      | Stata | Julia 1st run | Julia 2nd run | Speedup |
| ------------ | ----- | ------------- | ------------- | ------- |
| `@egen`      | 4.90s | 1.23s         | 0.37s         | 13x     |
| `@collapse`  | 0.92s | 0.26s         | 0.15s         | 8x      |
| `@regress`   | 0.89s | 1.94s         | 0.14s         | 6x      |
| `@tabulate`  | 2.14s | 0.46s         | 0.09s         | 20x     |
| `@summarize` | 10.40s | 0.60s         | 0.37s         | 28x     |

## Commands

### Filtering columns and rows
```@docs
@keep
```

```@docs
@drop
```

### Modifying columns
```@docs
@generate
```

```@docs
@replace
```

```@docs
@egen
```

### Grouping data
```@docs
@collapse
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

## Gotchas for Julia users
### Everything is a macro
### Comma is used for options
### Automatic variable name substitution
### Automatic vectorization
### Handling missing values

## Gotchas for Stata users
### All commands begin with `@`
### `@collapse` has same syntax as `@egen`
