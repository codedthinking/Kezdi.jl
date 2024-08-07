# 2024-03-05
## Why Julia? Why Kezdi.jl?
1. A single language for all scientific computing. Economists very often combine multiple languages to get their work done. [data from 200 replication packages] Data cleaning, statistical analysis and computational simulations are often done in different languages. This is not only inefficient, but also makes it difficult to reproduce and share research.
2. Reproducibility. An open source language with world-class environment and package management.
3. Performance. Scientists do not care much about speed. Code often takes weeks to run. [data from 200 replication packages] Performance matters for fast iteration, which can not only speed up the research process, but also make the code more reproducible.
4. Domain-specific syntax. Data analysis and statistics have their own conventions. Stata (R) provides an easy-to-use and easy-to-learn interface for data analysis. 
5. Consistent API. In any tool, let alone among multiple tools and languages, the APIs are often inconsistent. This makes it difficult to learn and use new tools.
6. Curated tools and methods. Adopting open source tools and methods is difficult. There are too many options, and it is difficult to know which ones are necessary, and which ones are reliable.
7. Proper abstractions. A complete language should provide proper abstractions for different tasks. Data structures, functions, modules, should come naturally to the user.

## Milestones
### `if`, `in`, `by` and options parsing
This should work for all commands:

```stata
by country: summarize gdp if gdp > 0, detail
```

### Variable scoping
```julia
@generate y = x^2
```
should look for `y` in the dataframe, `x` in the dataframe, but if not found, then in the global scope.

### Data manipulation commands
- generate
- replace
- egen
- collapse
- merge
- join
- cross
- append
- reshape

### File and df operations
How to interact with different DataFrames? The default is to work on a single df, but how to do `merge`, `append`, `join` and `cross`.

### Side effect commands
- tabulate
- table
- summarize
- display (shall we replace by print?)

### Curated statistical commands
Based on actual frequency of usage. 

## Architecture
### Multichannel communication
Stata has effectively multichannel communication between statements. Each statement manipulates the dataframe (channel 1), but can return values in `r()` or `e()` or `_b` (two more channels). They can also have other side effects.

We may need to implement multi-channel piping (coroutines?) to bring back this feeling to users.

Normal piping takes df -> df functions only.

# 2024-05-02
## State of the art
### The Stata universe
1. Most **applied micreconomists** use Stata (70% of REStud packages, followed by Matlab 50%, and R 16%)
2. Often combined with another language (e.g. Python for cleaning, Matlab for simulation)
3. Vast majority (88%) of Stata scripts are devoted to data cleaning

### The Julia universe
1. DataFrames.jl de facto standard for tabular data
2. Many grammars for data cleaning: Query, DataFramesMeta, TidierData

Broad goal:

> Port Stata syntax and tools to Julia, like Tidier.jl did tidyverse.

Key tradeoff:

> Users like convenience and sensible default choices. But explicit, verbose software is less bug prone.

Be mindful of trade-off throughout the project. Maybe the user can calibrate their level of risk tolerance.

## Missing pieces in the Julia data universe

1. **Missing values**
	1. Stata has common sense defaults
		1. also some quirky behavior, like . > anything
	2. Risky choices, make them explicit
	3. Input/output (how to read and write missing values) vs algebra (what is 4 + missing?)
	4. Type conversion is a pain, cannot put a `missing` into a vector of `Float`s
2. Better documentation for existing packages
3. Maintainers, curation for existing regression packages
4. **Wald test**
	1. formula language for linear constraints
	2. `test gender == schooling + 5`
5. ML estimation package
	1. standard errors, clustering
	2. **regtables**

## Best of Stata
```stata
replace y = 0 if y < 0
regress y x if x > 0
```
contrasted with much harder syntax in Pandas, R, Julia.

`if` can be used with *almost all* commands. Convenient *and* verbose, no trade-off here. This feature should be implemented if at all possible.

Sensible default choices for missing values.

By default, operations are on variables (columns, vectors).

Opinion: variable scoping is interesting.
```stata
scalar n_users = 5
generate y = n_users + 1
replace y = . if y < n_users
```
BUT can lead to dangerous bugs:
```stata
scalar y = 5
generate y = y + 1
```
Contrasted with some existing grammars
- explicitly refer to a df column, `df.x`, `df[!, :x]`
- refer to symbol, like `:x`, `:y` or strings, `"x"` `"y"`
- TidierData does it well, i.e., most like Stata

Explicit `merge m:1` vs `merge 1:1` 

`by x: egen z = sum(1)`

Value labels are different for categorical vectors.
- BUT: no strings as factors
- in Stata, variables don't have coding, `i.gender` and `c.gender` can be in the same regression
- i. notation, changing the base, subset of categories
## Not so good in Stata
- quirky syntax, like egen vs collapse
- no proper function returns
## Code examples
```julia
using TidierData
@chain data begin
	@select command canonical_form
	@filter canonical_form == "generate"
	@group_by command
	@summarize n = n()
	@ungroup
	@arrange desc(n)
end
```
```julia
using Kezdi
@chain data begin
	@keep command canonical_form
	@keep @if canonical_form == "generate"
	@egen n = count(), by(canonical_form)
	@sort -n
end
```

```Stata
replace y = . if y < 5
```

```julia
const n_users = 5
model_object = @chain data begin
	@replace y = 0 @if y < 0
	@regress y x @if x > n_users, vce(cluster country)
end
```

```julia
const n_users = 5
@chain data begin
	@replace y = 0 @if y < 0
	@aside model_object = @regress y x @if x > n_users, vce(cluster country)
	@keep @if x < 0	
end
```

# 2024-05-28

```julia
@with globals(x, y) df begin
	@replace gdp = x @if gdp < y
	for t = 1999:2004
		@keep @if year == t
		@summarize gdp
	end
end
```

We want
- globals to be passed into block
- `t` to be recognized as a local in code block
- `@summarize` to act as a side effect, not changing `df`
- each for loop to start with the same dataframe
	- [ ] check if this works in `@chain`

`@with` needs to modify each Kezdi command to include `df` (or appropriately modified, check `@chain`) and also `globals`

so that command-level parsing should take the form
```julia
df2 = @replace df globals(x, y) gdp = x @if gdp < y
for t = 1999:2004
	@keep df globals(x, y) locals(t) @if year == t
	@summarize df2 globals(x, y) locals(t) gdp
end
```

Can you introduce abstractions?
```julia
function summarize(df::DataFrame, x::Symbol)
	@with df macros(x) begin
		@summarize x
	end
end
summarize(df, :gdp)
summarize(df, :population)
```

See what `dbt` does to make SQL work nice with abstractions.
```sql
select * from gdps where country = "{{ country }}" 
```

# 2024-06-11
## Variable names
Tidyverse has all kinds of functions to deal with more than one column, like `beginswith`. 

Stata has a good and widely used varlist syntax: `var*`, `var?b` and `var1-var27`. This may need to be implemented later, based on https://dataframes.juliadata.org/stable/lib/functions/#Working-with-column-names This is potentially low on the risk-convenience tradeoff, especially `var1-var27` (we don't know what columns are in between). In terms of syntax, `var*` and `var?b` have to be rewritten, e.g., `var...` and `var.b` and could work.

We may want to enforce that commands can only be used in `@with` because Stata syntax is so much different from Julia syntax. 

```julia
regress(df, y ~ x)

@chain df begin
    regress y ~ x
end
```
but
```julia
@regress(df, y ~ x)
# raises an error

@with df begin
    regress y ~ x
end
# runs beautifully
```

This can be achieved by `@with` passing a known token inside the code block and `@regress` checks for the existence of this token.

An in-place version of `@with!` should do everything in place. This can mean all commands operating in place (preferred for performance reasons). Like `@with!` transforms `@replace` to `@replace!` and does not need to pass `df` to the next command. Alternatively, `macro @with! df = @with df`. Because all commands work in place in Stata, this may be the preferred mode of operation. 

## 2024-06-28
### Benefits for Stata users
1. Free
2. Speed
   - StatFiles.jl reading .dta files slowly is a major obstacle
   - `egen` has to be sped up
3. Single language

## Programming-related benefits
4. Use proper data structures
   - fix `vlist[1]` and `in vlist`
   - check other data structures like named tuple or dict
5. Use functions
   - non-standard evaluation makes it hard to wrap Kezdi.jl code in functions
6. For loops
   - implement `scalars()` and automatic expansion of locals in context

# 2024-07-12 In-flight debugging session
```julia
julia> using Kezdi

julia> module MyModule
       myfunc(x) = 2x
       end
Main.MyModule

julia> df = DataFrame(x = 1:10)
10×1 DataFrame
 Row │ x
     │ Int64
─────┼───────
   1 │     1
   2 │     2
   3 │     3
   4 │     4
   5 │     5
   6 │     6
   7 │     7
   8 │     8
   9 │     9
  10 │    10

julia> @with df @generate y = MyModule.myfunc(x)
10×2 DataFrame
 Row │ x      y
     │ Int64  Int64
─────┼──────────────
   1 │     1      2
   2 │     2      4
   3 │     3      6
   4 │     4      8
   5 │     5     10
   6 │     6     12
   7 │     7     14
   8 │     8     16
   9 │     9     18
  10 │    10     20
```

How about aggreator function?

```julia
julia> module MyModule
       myfunc(x) = 2x
       myaggreg(v::Vector) = sum(x.^2)
       end
WARNING: replacing module MyModule.
Main.MyModule

julia> @with df @egen y = MyModule.myaggreg(x)
┌ Warning: transform!(var"##237", [:x] => (((x,)->(passmissing(MyModule.myaggreg)).(x)) => $(QuoteNode("y"))))
└ @ Kezdi ~/Tresorit/Mac/code/julia/Kezdi.jl/src/commands.jl:100
ERROR: MethodError: no method matching myaggreg(::Int64)

Closest candidates are:
  myaggreg(::Vector)
   @ Main.MyModule REPL[8]:3
```

This means it was vectorized at compile time, but it is found at runtime.