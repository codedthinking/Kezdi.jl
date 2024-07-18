```@meta
CurrentModule = Kezdi
```

# Kezdi.jl Documentation
Kezdi.jl is a Julia package that provides a Stata-like interface for data manipulation and analysis. It is designed to be easy to use for Stata users who are transitioning to Julia.[^stata] 

It imports and reexports [CSV](https://csv.juliadata.org/stable/), [DataFrames](https://dataframes.juliadata.org/stable/), [FixedEffectModels](https://fixedeffectmodelsjl.readthedocs.io/en/latest/), [FreqTables](https://github.com/nalimilan/FreqTables.jl), [ReadStatTables](https://github.com/piever/ReadStatTables.jl), [Statistics](https://docs.julialang.org/en/v1/stdlib/Statistics/), and [StatsBase](https://juliastats.org/StatsBase.jl/stable/). These packages are not covered in this documentation, but you can find more information by following the links.

## Getting started
!!! warning "Kezdi.jl is in beta"
    `Kezdi.jl` is currently in beta. We have more than 380 unit tests and a large code coverage. [![Coverage](https://codecov.io/gh/codedthinking/Kezdi.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/codedthinking/Kezdi.jl) The package, however, is not guaranteed to be bug-free. If you encounter any issues, please report them as a [GitHub issue](https://github.com/codedthinking/Kezdi.jl/issues/new).

    If you would like to receive updates on the package, please star the repository on GitHub and sign up for [email notifications here](https://relentless-producer-1210.ck.page/62d7ebb237).


### Installation
To install the package, run the following command in Julia's REPL:

```julia
using Pkg; Pkg.add("Kezdi")
```

Every Kezdi.jl command is a macro that begins with `@`. These commands operate on a global `DataFrame` that is set using the `setdf` function. Alternatively, commands can be executed within a `@with` block that sets the `DataFrame` for the duration of the block.

### Example
```@repl mtcars
using Kezdi
using RDatasets

df = dataset("datasets", "mtcars")
setdf(df)

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

Alternatively, you can use the `@with` block to avoid writing to a global `DataFrame`:
```@repl mtcars
renamed_df = @with df begin
    @rename HP Horsepower
    @rename Disp Displacement
    @rename WT Weight
    @rename Cyl Cylinders
end

@with renamed_df begin
    @tabulate Gear
    @keep @if Gear == 4
    @keep MPG Horsepower Weight Displacement Cylinders
    @summarize MPG
    @regress log(MPG) log(Horsepower) log(Weight) log(Displacement) fe(Cylinders), robust 
end
```

## Benefits of using Kezdi.jl
### Free and open-source
### Speed

| Command      | Stata | Julia 1st run | Julia 2nd run | Speedup |
| ------------ | ----- | ------------- | ------------- | ------- |
| `@egen`      | 4.90s | 1.36s         | 0.36s         | 14x     |
| `@collapse`  | 0.92s | 0.39s         | 0.28s         | 3x      |
| `@tabulate`  | 2.14s | 0.68s         | 0.09s         | 24x     |
| `@summarize` | 10.40s | 0.58s         | 0.36s         | 29x     |
| `@regress`   | 0.89s | 1.95s         | 0.11s         | 8x      |

See the benchmarking code for [Stata](https://github.com/codedthinking/Kezdi.jl/blob/main/docs/examples/benchmark.do) and [Kezdi.jl](https://github.com/codedthinking/Kezdi.jl/blob/main/docs/examples/benchmark.jl).

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
function geometric_mean(x::Vector)
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

### Use on another DataFrame
```@docs
@with
```

```@docs
@with!
```

## Differences to standard Julia and DataFrames syntax
To maximize convenience for Stata users, Kezdi.jl has a number of differences to standard Julia and DataFrames syntax.

### Everything is a macro
While there are a few convenience functions, most Kezdi.jl commands are macros that begin with `@`.

```julia
@tabulate Gear
```

### Comma is used for options
Due to this non-standard syntax, Kezdi.jl uses the comma to separate options.

```julia
@regress log(MPG) log(Horsepower), robust
```

Here `log(MPG)` and `log(Horsepower)` are the dependent and independent variables, respectively, and `robust` is an option. Options may also have arguments, like

```julia
@regress log(MPG) log(Horsepower), cluster(Cylinders)
```

### Automatic variable name substitution
Column names of the data frame can be used directly in the commands without the need to prefix them with the data frame name or using a Symbol.

```julia 
@generate logHP = log(Horsepower)
```

!!! warning "No symbols or special strings"
    Other data manipulation packages in Julia require column names to be passed as symbols or strings. Kezdi.jl does not require this, and it will not work if you try to use symbols or strings.

!!! danger "Reserved words cannot be used as variable names"
    Julia reserved words, like `begin`, `export`, `function` and standard types like `String`, `Int`, `Float64`, etc., cannot be used as variable names in Kezdi.jl. If you have a column with a reserved word, rename it *before* passing it to Kezdi.jl.

If you want to avoid variable name substitution, you currently have two workarounds. One is to refer to the fully qualified name of the variable, including the module. The other is to define a constant function.

```julia
df = DataFrame(x = 1:2, y = 3:4)
x = 5
y() = 6
@with df begin
    @generate x1 = x
    @generate x2 = Main.x
    @generate y1 = y
    @generate y2 = y()
end
```
results in
```julia
2×6 DataFrame
 Row │ x      y      x1     x2     y1     y2
     │ Int64  Int64  Int64  Int64  Int64  Int64
─────┼──────────────────────────────────────────
   1 │     1      3      1      5      3      6
   2 │     2      4      2      5      4      6
```

### Automatic vectorization
All functions are automatically vectorized, so there is no need to use the `.` operator to broadcast functions over elements of a column. 

```julia
@generate logHP = log(Horsepower)
```

If you want to turn off automatic vectorization, use the `~` symbol:
```julia
@generate logHP = ~log(Horsepower)
```

The exception is when the function operates on Vectors, in which case Kezdi.jl understands you want to apply the function to the entire column.

```julia
@collapse mean_HP = mean(Horsepower), by(Cylinders)
```

If you need to apply a function to individual elements of a column, you need to vectorize it with adding `.` after the function name:

```julia
@generate words = split(Model, " ")
@generate n_words = length.(words)
```

!!! tip "Note: `length(words)` vs `length.(words)`" 
    Here, `words` becomes a vector of vectors, where each element is a vector of words in the corresponding `Model` string. The function `legth.` will operate on each cell in `words`, counting the number of words in each `Model` string. By contrast, `length(words)` would return the number of elements in the `words` vector, which is the number of rows in the DataFrame.

### The `@if` condition
Almost every command can be followed by an `@if` condition that filters the data frame. The command will only be executed on the subset of rows for which the condition evaluates to `true`. The condition can use any combination of column names and functions.

```julia
@summarize MPG @if Horsepower > median(Horsepower)
```

!!! tip "Note: vector functions in `@if` conditions"
    Autovectorization rules also apply to `@if` conditions. If you use a vector function, it will be evaluated on the *entire* column, before subseting the data frame. By contrast, vector functions in `@generate` or `@collapse` commands are evaluated on the subset of rows that satisfy the condition.

    ```julia
    @generate HP_p75 = median(Horsepower) @if Horsepower > median(Horsepower)
    ```

    This code computes the median of horsepower values *above the median*, that is, the 75th percentile of the horsepower distribution. Of course, you can more easily do this calculation with `@summarize`:

    ```julia
    s = @summarize Horsepower
    s.p75
    ```

### Handling missing values
Kezdi.jl ignores missing values when aggregating over entire columns. 

```julia
@with DataFrame(A = [1, 2, missing, 4]) begin
    @collapse mean_A = mean(A)
end
```
returns `mean_A = 2.33`.

Other functions typically return `missing` if any of the values are missing. If a function does not accept missing values, Kezdi.jl will pass it through `passmissing` to handle missing values.

You can also manually check for missing values with the `ismissing` function.

```julia
@with DataFrame(x = [1, 2, missing, 4]) begin
    @generate y = log(x)
end
```
returns 
```julia
4×2 DataFrame
 Row │ x        y
     │ Int64?   Float64?
─────┼─────────────────────────
   1 │       1        0.0
   2 │       2        0.693147
   3 │ missing  missing
   4 │       4        1.38629
```

The same will hold for `Dates.year`, even though this function does not accept missing values.

```julia
julia> @with DataFrame(x = [1, 2, missing, 4]) begin
           @generate y = Dates.year(x)
       end
4×2 DataFrame
 Row │ x        y
     │ Int64?   Int64?
─────┼──────────────────
   1 │       1        1
   2 │       2        1
   3 │ missing  missing
   4 │       4        1
```

!!! warning "In `@if` conditions, `missing` is treated as `false`"
    In `@if` conditions, `missing` is treated as `false`. This is expected behavior from users, because when they test for a condition, they expect it to be `true`, not `missing`.

    ```julia
    @with DataFrame(x = [1, 2, missing, 4]) begin
        @keep @if x <= 2
    end
    ```
    returns `[1, 2]`.

### Use `cond` instead of ternary operators
Ternary operators like `x ? y : z` are not vectorized in Julia. Instead, use the `cond` function, which provides the exact same functionality.

```julia
@with DataFrame(x = [1, 2, 3, 4]) begin
    @generate y = cond(x <= 2, 1, 0)
end
```

Note that you can achieve the same result with the more readable code
```julia
@with DataFrame(x = [1, 2, 3, 4]) begin
    @generate y = 1  @if x <= 2 
    @replace y = 0 @if x > 2
end
```

!!! warning "`cond` may not work as you expect with missing values"
    Because `cond` is vectorized and vectorized functions ignore missing values, this may lead to unexpected behavior. Use `@replace @if` instead.

### Row-count variables
The variable `_n` refers to the row number in the data frame, `_N` denotes the total number of rows. These can be used in `@if` conditions, as well.

```julia
@with DataFrame(A = [1, 2, 3, 4]) begin
    @keep @if _n < 3
end
```

## Differences to Stata syntax
### All commands begin with `@`
To allow for Stata-like syntax, all commands begin with `@`. These are macros that rewrite your Kezdi.jl code to `DataFrames.jl` commands.

```julia
@tabulate Gear
@keep @if Gear == 4
@keep Model MPG Horsepower Weight Displacement Cylinders
```

### `@if` condition also begins with `@`
[The `@if` condition](@ref) is non-standard behavior in Julia, so it is also implemented as a macro.

### `@collapse` has same syntax as `@egen`
Unlike Stata, where `egen` and `collapse` have different syntax, Kezdi.jl uses the same syntax for both commands.

```julia
@egen mean_HP = mean(Horsepower), by(Cylinders)
@collapse mean_HP = mean(Horsepower), by(Cylinders)
```

### Different function names
To maintain compatibility with Julia, we had to rename some functions. For example, `count` is called `rowcount`, `missing` is called `ismissing`, `max` is `maximum`, and `min` is `minimum` in Kezdi.jl.

### Missing values
In Julia, the result of any operation involving a missing value is `missing`. The only exception is the `ismissing` function, which returns `true` if the value is missing and `false` otherwise. You *cannot* check for missing values with `== missing`.

For convenience, Kezdi.jl has special rules about [Handling missing values](@ref). We also extended the `ismissing` function to work with multiple arguments.

```julia
@with DataFrame(x = [1, 2, missing, 4], y = [1, missing, 3, 4]) begin
    @generate z = ismissing(x, y)
end
4×3 DataFrame
 Row │ x        y        z
     │ Int64?   Int64?   Bool
─────┼─────────────────────────
   1 │       1        1  false
   2 │       2  missing   true
   3 │ missing        3   true
   4 │       4        4  false
```

Missing is not greater than anything, so comparison with missing values will always return `missing`. 

!!! warning "In `@if` conditions, `missing` is treated as `false`"
    In `@if` conditions, `missing` is treated as `false`. This is expected behavior from users, because when they test for a condition, they expect it to be `true`, not `missing`.

    ```julia
    @with DataFrame(x = [1, 2, missing, 4]) begin
        @keep @if x <= 2
    end
    ```
    returns `[1, 2]`.

## Convenience functions
```@docs
distinct
```

```@docs
rowcount
```

```@docs
keep_only_values
```

```@docs
ismissing
```

```@docs
cond
```

## Acknowledgements
[^stata]: Stata is a registered trademark of StataCorp LLC. Kezdi.jl is not affiliated with StataCorp LLC.

Inspiration for the package came from [Tidier.jl](https://tidierorg.github.io/Tidier.jl/stable/), a similar package launched by Karandeep Singh that provides a dplyr-like interface for Julia. Johannes Boehm has also developed a similar package, [Douglass.jl](https://github.com/jmboehm/Douglass.jl).

The package is built on top of [DataFrames.jl](https://dataframes.juliadata.org/stable/), [FreqTables.jl](https://github.com/nalimilan/FreqTables.jl) and [FixedEffectModels.jl](https://github.com/FixedEffects/FixedEffectModels.jl). The `@with` function relies on [Chain.jl](https://github.com/jkrumbiegel/Chain.jl) by Julius Krumbiegel.

The package is named after [Gabor Kezdi](https://kezdigabor.life/), a Hungarian economist who has made significant contributions to [teaching data analysis](https://gabors-data-analysis.com/).