## 2024-05-28

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
