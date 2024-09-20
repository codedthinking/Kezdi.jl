module Backend
import DataFrames

export rename!, names

mutable struct TableReference
    colnames::Vector{AbstractString}
end

names(t::TableReference) = t.colnames

function rename!(t::TableReference, p::Pair{Symbol, Symbol})
    String(p[1]) in t.colnames || error("$(p[1]) not found")
    t.colnames = [col == String(p[1]) ? String(p[2]) : col for col in t.colnames]
end

rename!(t::DataFrames.AbstractDataFrame, p::Pair{Symbol, Symbol}) = DataFrames.rename!(t, p)

end # module