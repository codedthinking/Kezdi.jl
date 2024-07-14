use(fname::AbstractString) = readstat(fname) |> DataFrame |> setdf

"""
    getdf() -> AbstractDataFrame

Return the data frame set in the current scope.
"""
getdf() = Kezdi.runtime_context[].df

display_and_return(x) = (display(x); x)

"""
    distinct(x::AbstractVector) = unique(x)

Convenience function to get the distinct values of a vector.
"""
distinct(x::AbstractVector) = unique(x)
distinct(x::Base.SkipMissing) = distinct(collect(x))

"""
    rowcount(x::AbstractVector) = length(keep_only_values(x))

Count the number of valid values in a vector.
"""
rowcount(x::AbstractVector) = length(keep_only_values(x))
rowcount(x::Base.SkipMissing) = length(collect(x))

tabulate(df::AbstractDataFrame, columns::Vector{Symbol}) = freqtable(df, columns...)

function summarize(df::AbstractDataFrame, column::Symbol)::Summarize
    data = df[!, column] |> keep_only_values
    n = length(data)
    sum_val = sum(data)
    mean_val = mean(data)
    std_dev = std(data)
    variance = var(data)
    skewness_val = skewness(data)
    # julia reports excess kurtosis, so we add 3 to get the kurtosis
    kurtosis_val = 3.0 + kurtosis(data)
    
    percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    percentiles_values = quantile(data, percentiles ./ 100; alpha=0.5, beta=0.5)

    Summarize(
        column,
        n,
        n,
        mean_val,
        variance,
        std_dev,
        skewness_val,
        kurtosis_val,
        sum_val,
        minimum(data),
        maximum(data),
        percentiles_values[1],
        percentiles_values[2],
        percentiles_values[3],
        percentiles_values[4],
        percentiles_values[5],
        percentiles_values[6],
        percentiles_values[7],
        percentiles_values[8],
        percentiles_values[9]
    )
end

regress(df::AbstractDataFrame, formula::Expr) = :(reg($df, $formula))
counter(df::AbstractDataFrame) = nrow(df)
counter(gdf::GroupedDataFrame) = [nrow(df) for df in gdf]

# dummy function for do-not-vectorize
"""
    DNV(f(x))

Indicate that the function `f` should not be vectorized. The name DNV is only used for parsing, do not call it directly.
"""
DNV(args...; kwargs...) = error("This function should not be directly called. It is used to indicate that a function should not be vectorized. For example, @generate y = DNV(log(x))")

isvalue(x) = true
isvalue(::Missing) = false
isvalue(::Nothing) = false
isvalue(x::Number) = isinf(x) || isnan(x) ? false : true
isvalue(args...) = all(isvalue.(args))

"""
    keep_only_values(x::AbstractVector) -> AbstractVector

Return a vector with only the values of `x`, excluding any `missing`` values, `nothing`s, `Inf`a and `NaN`s.
"""
keep_only_values(x) = filter(isvalue, collect(skipmissing(x)))

"""
    ismissing(args...) -> Bool

Return `true` if any of the arguments is `missing`.
"""
Base.ismissing(args...) = any(ismissing.(args))