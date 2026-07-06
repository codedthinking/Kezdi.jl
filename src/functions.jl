use(fname::AbstractString) = readstat(fname) |> DataFrame |> setdf
save(fname::AbstractString) = writestat(fname, getdf())

function append(fname::AbstractString)
    ispath(fname) || ArgumentError("File $fname does not exist.") |> throw
    _, ext = splitext(fname)
    if ext in [".dta", ".save", ".por", ".sas7bdat", ".xpt"]
        df = readstat(fname) |> DataFrame
    else
        df = CSV.read(fname, DataFrame)
    end
    cdf = getdf()
    cdf, df = create_cols(cdf, df)
    df = vcat(cdf, df)
    setdf(df)
end

function append(df::DataFrame)
    cdf, df = create_cols(getdf(), df)
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
setdf(df::Union{AbstractDataFrame,Nothing}) = global _global_dataframe = isnothing(df) ? nothing : copy(df)
display_and_return(x) = isinteractive() ? (display(x)) : (display(x); x)

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
isvalue(x::Number) = isfinite(x)
isvalue(args...) = all(isvalue, args)

"""
    keep_only_values(x::AbstractVector) -> AbstractVector

Return a vector with only the values of `x`, excluding any `missing` values, `nothing`s, `Inf`s and `NaN`s.
"""
keep_only_values(x) = collect(Iterators.filter(isvalue, skipmissing(x)))

"""
    tomask(m, n) -> AbstractVector{Bool}

Turn a condition result `m` into a length-`n` boolean row mask: `missing`
becomes `false`, and a scalar condition (e.g. `@if 2 < 4`) is expanded to a
full-length vector.
"""
tomask(m::AbstractVector, n::Int) = coalesce.(m, false)
tomask(m, n::Int) = fill(coalesce(m, false), n)

"""
    anymissing(args...) -> Bool

Return `true` if any of the arguments is `missing`. Multi-argument
`ismissing(x, y)` written inside a Kezdi command is rewritten to this function,
since `Base.ismissing` has no multi-argument method.
"""
anymissing(args...) = any(ismissing, args)

"""
    signature_mentions(f, T) -> Bool

Return `true` if any method of `f` has an argument annotated with `T` or a
supertype of `T`, excluding `Any`. This is the world-age-correct, run-time
replacement for `InteractiveUtils.methodswith(T, f; supertypes=true)`, which the
package used to call at macro-expansion time via `Main.eval`.
"""
function signature_mentions(@nospecialize(f), @nospecialize(T::Type))
    for m in methods(f)
        sig = Base.unwrap_unionall(m.sig)
        sig isa DataType || continue
        for p in sig.parameters[2:end]
            p isa Core.TypeofVararg && (p = Base.unwrapva(p))
            p isa TypeVar && (p = p.ub)
            p === Any && continue
            p isa Type || continue
            T <: p && return true
        end
    end
    return false
end

operates_on_vector(@nospecialize(f)) = signature_mentions(f, Vector)
operates_on_missing(@nospecialize(f)) =
    f === ismissing || f === anymissing || signature_mentions(f, Missing)

"""
    apply_function(f, args...)

Apply `f` the way Kezdi commands need it, deciding at run time whether to
broadcast or to pass whole columns:

- functions that operate on vectors (like `mean`, `sum`) receive the columns
  with `missing`/`NaN`/`Inf` removed;
- functions that already handle `missing` are broadcast as-is;
- every other function is broadcast wrapped in `passmissing`.
"""
function apply_function(f, args...)
    f === getindex && return f.(args...)
    operates_on_vector(f) && return f(map(keep_only_values, args)...)
    operates_on_missing(f) && return f.(args...)
    return passmissing(f).(args...)
end

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

"""
    mvreplace(x, y)

Return `y` if `x` is `missing`, otherwise return `x`. If `x` is a vector, the operation is vectorized. This function mimics `x ? y : z`, which cannot be vectorized.
"""
mvreplace(x, y) = ismissing(x) ? y : x
