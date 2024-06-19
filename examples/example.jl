include("../../With.jl/src/With.jl")
using .With, DataFrames, Logging #, Kezdi
global_logger(Logging.ConsoleLogger(stderr, Logging.Info))
include("../src/transpiler.jl")
include("../src/macros.jl")

EXPLICIT_MISSING = false
STATSMODELS_FORMULA = true

env(x) = x
scalars(x...) = x

df = DataFrame(
    population = [100, 200, 300, missing],
    gdp = [1000, missing, 9000, 16000],
    group = ["blue", "blue", "red", "red"]
)

# illustrate Stata-like syntax
@with df begin
    @replace gdp = 4000 @if ismissing(gdp)
    @generate gdp_per_capita = gdp / population
    @egen mean_gdp_per_capita = mean(gdp_per_capita) @by group
    @generate small_country = population < 250
    @regress ln(gdp) ln(population) i.group, robust
    @test ln(population) == 2
end

# env can set default behavior on missings, formulae
@with df env(EXPLICIT_MISSING || STATSMODELS_FORMULA) begin
    @regress ln(gdp) ~ ln(population) + fe(group) @if !ismissing(gdp) && !ismissing(population), robust
end

# can pass outside variables into block, but only explicitly
const cutoff = 250
@with df scalars(cutoff) begin
    @generate small_country = population < cutoff
end

# can also collapse
groups = @with df begin
    @collapse mean_gdp = mean(gdp) min_gdp = min(gdp) @by group
end

# with should also work in place
@with! df begin
    @replace gdp = 4000 @if ismissing(gdp)
    @generate gdp_per_capita = gdp / population
    @egen mean_gdp_per_capita = mean(gdp_per_capita) @by group
end