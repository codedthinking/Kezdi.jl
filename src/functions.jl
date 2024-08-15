use(fname::AbstractString) = readstat(fname) |> DataFrame |> setdf
save(fname::AbstractString) = writestat(fname, getdf())
function append(fname::AbstractString)
    ispath(fname) || ArgumentError("File $fname does not exist.") |> throw
    _, ext = splitext(fname)
    if ext in [".dta", ".sav", ".por", ".sas7bdat", ".xpt"]
        df = readstat(fname) |> DataFrame
    else
        df = CSV.read(fname, DataFrame)
    end
    cdf = getdf()
    cdf, df = create_cols(cdf, df)
    df = vcat(cdf,df)
    setdf(df)
end

function append(df::DataFrame)
    cdf, df  = create_cols(getdf(), df)
    setdf(vcat(cdf, df))
end

function create_cols(cdf::DataFrame, df::DataFrame)
    if names(cdf) != names(df)
        for col in names(df)
            if col ∉ names(cdf)
                cdf[!, col] .= missing
            end
        end
        for col in names(cdf)
            if col ∉ names(df)
                df[!, col] .= missing
            end
        end
    end
    return cdf, df
end


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

"""
    cond(x, y, z)

Return `y` if `x` is `true`, otherwise return `z`. If `x` is a vector, the operation is vectorized. This function mimics `x ? y : z`, which cannot be vectorized.
"""
cond(x::Any, y, z) = x ? y : z
cond(x::AbstractVector, y, z) = cond.(x, y, z)

prompt(s::AbstractString="Kezdi.jl") = string(Crayon(bold=true, foreground=:green), "$s> ", Crayon(reset=true))

# do not clash with DataFrames.describe
function _describe(df::AbstractDataFrame, cols::Vector{Symbol}=Symbol[])
    table = isempty(cols) ? describe(df) : describe(df[!, cols])
    table.eltype = nonmissingtype.(table.eltype)
    table[!, [:variable, :eltype]]
end

mvreplace(x, y) = ismissing(x) ? y : x