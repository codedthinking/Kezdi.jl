use(fname::AbstractString) = readstat(fname) |> DataFrame |> setdf

"""
    getdf() -> AbstractDataFrame

Return the global data frame.
"""
getdf() = _global_dataframe

"""
    setdf(df::Union{AbstractDataFrame, Nothing})

Set the global data frame.
"""
setdf(df::Union{AbstractDataFrame, Nothing}) = global _global_dataframe = df
display_and_return(x) = (display(x); x)

"""
    distinct(x::AbstractVector) = unique(x)

Convenience function to get the distinct values of a vector.
"""
distinct(x::AbstractVector) = unique(x)
distinct(x::Base.SkipMissing) = distinct(collect(x))

"""
    rowcount(x::AbstractVector) = length(collect(skipmissing(x)))

Count the number of non-missing values in a vector.
"""
rowcount(x::AbstractVector) = length(collect(skipmissing(x)))
rowcount(x::Base.SkipMissing) = length(collect(x))

tabulate(df::AbstractDataFrame, columns::Vector{Symbol}) = freqtable(df, columns...)

function summarize(df::AbstractDataFrame, column::Symbol)::Summarize
    data = df[!, column] |> skipmissing |> collect
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