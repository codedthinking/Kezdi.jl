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
