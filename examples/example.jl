using Kezdi

EXPLICIT_MISSING = false
STATSMODELS_FORMULA = true

env(x) = x
scalars(x...) = x

df = DataFrame(
    population = [100, 200, 300, missing],
    gdp = [1000, missing, 9000, 16000],
    group = ["blue", "blue", "red", "red"],
    country = ["HU", "DE", "US", "UK"]
)
@show df

# illustrate Stata-like syntax
df2 = @with df begin
    @replace gdp = 4000 @if ismissing(gdp)
    @generate gdp_per_capita = gdp / population
    @egen mean_gdp_per_capita = mean(gdp_per_capita), by(group)
    @generate small_country = population < 250
    @generate ln_gdp = log(gdp)
    @regress ln_gdp ln(population) fe(group)
    #@test ln(population) == 2
end
@show df2

# env can set default behavior on missings, formulae
# @with df env(EXPLICIT_MISSING || STATSMODELS_FORMULA) begin
#     @regress ln(gdp) ~ ln(population) + fe(group) @if !ismissing(gdp) && !ismissing(population), robust
# end

# can pass outside variables into block, but only explicitly
# const cutoff = 250
# @with df scalars(cutoff) begin
#     @generate small_country = population < cutoff
# end

# can also collapse
groups = @with df begin
    @collapse mean_gdp = mean(gdp) min_gdp = minimum(gdp), by(group)
end
@show groups

# with should also work in place
@with! df begin
    @replace gdp = 4000 @if ismissing(gdp)
    @generate gdp_per_capita = gdp / population
    @egen mean_gdp_per_capita = mean(gdp_per_capita), by(group)
end
@show df