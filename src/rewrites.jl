# use multiple dispatch to generate code 
rewrite(command::Command) = rewrite(Val(command.command), command)

function rewrite(::Val{:summarize}, command::Command)
    dfname = command.df
    column = extract_variable_references(command.arguments[1])
    bitmask = build_bitmask(command)
    quote
        Kezdi.summarize(view($dfname, $bitmask, :), $column[1])
    end |> esc
end

function rewrite(::Val{:regress}, command::Command)
    dfname = command.df
    bitmask = build_bitmask(command)
    variables = command.arguments
    sdf = gensym()
    quote
        local $sdf = view($dfname, $bitmask, :)
        reg($sdf, @formula $(variables[1]) ~ $(sum(variables[2:end])))
    end |> esc
end

function rewrite(::Val{:generate}, command::Command)
    dfname = command.df
    target_column = get_LHS(command.arguments[1])
    # check that target_column does not exist in dfname
    df2 = gensym()
    sdf = gensym()
    bitmask = build_bitmask(df2, command.condition)
    lhs, rhs = split_assignment(command.arguments[1])
    RHS = replace_variable_references(sdf, rhs) |> vectorize_function_calls
    vars = vcat(extract_variable_references(rhs), extract_variable_references(command.condition))
    var_expr = add_special_variables(df2, vars)
    quote
        if !($target_column in names($dfname))
            local $df2 = copy($dfname)
            $var_expr
            $df2[!, $target_column] .= missing
            local $sdf = view($df2, $bitmask, :)
            $sdf[!, $target_column] .= $RHS
            $df2
        else
            ArgumentError("Column \"$($target_column)\" already exists in $(names($dfname))") |> throw
        end
    end |> esc
end

function rewrite(::Val{:replace}, command::Command)
    dfname = command.df
    lhs, rhs = split_assignment(command.arguments[1])
    target_column = get_LHS(command.arguments[1])
    # check that target_column does not exist in dfname
    df2 = gensym()
    sdf = gensym()
    third_vector = gensym()
    bitmask = build_bitmask(df2, command.condition)
    RHS = replace_variable_references(sdf, rhs) |> vectorize_function_calls
    #add_special_variables(df2, extract_variable_references(RHS) |> map(x -> x[2]) |> collect)
    quote
        if $target_column in names($dfname)
            local $df2 = copy($dfname)
            local $sdf = view($df2, $bitmask, :)
            if eltype($RHS) != eltype($sdf[!, $target_column])
                local $third_vector = Vector{eltype($RHS)}(undef, nrow($df2))
                $third_vector[$bitmask] .= $RHS
                $third_vector[.!$bitmask] .= $df2[!, $target_column][.!$bitmask]
                $df2[!, $target_column] = $third_vector
            else
                $sdf[!, $target_column] .= $RHS
            end
            $df2
        else
            ArgumentError("Column \"$($target_column)\" does not exist in $(names($dfname))") |> throw
        end
    end |> esc
end

function rewrite(::Val{:collapse}, command::Command)
    dfname = command.df
    #target_columns = get_LHS.(command.arguments)
    bitmask = build_bitmask(command)
    by_cols = get_by(command)
    # check that target_column does not exist in dfname
    df2 = gensym()
    sdf = gensym()
    gsdf = gensym()
    if isnothing(by_cols)
        combine_epxression = Expr(:call, :combine, sdf, build_assignment_formula.(command.arguments)...)
    else
        combine_epxression = Expr(:call, :combine, gsdf, build_assignment_formula.(command.arguments)...)
    end
    quote
        local $df2 = copy($dfname)
        local $sdf = view($df2, $bitmask, :)
        if isnothing($by_cols)
            $combine_epxression
        else
            local $gsdf = groupby($sdf, $by_cols)
            $combine_epxression
        end
    end |> esc
end

function rewrite(::Val{:keep}, command::Command)
    dfname = command.df
    bitmask = build_bitmask(command)
    # check that target_column does not exist in dfname
    df2 = gensym()
    quote
        local $df2 = copy($dfname)
        view($df2, $bitmask,  isempty($(command.arguments)) ? eval(:(:)) : collect($command.arguments))
    end |> esc
end

function rewrite(::Val{:drop}, command::Command)
    dfname = command.df
    if isnothing(command.condition)
        return :(select($dfname, Not(collect($(command.arguments))))) |> esc
    end 
    bitmask = build_bitmask(dfname, :(!($command.condition)))
    :($dfname[$bitmask, :]) |> esc
end

function rewrite(::Val{:egen}, command::Command)
    dfname = command.df
    target_column = get_LHS(command.arguments[1])
    by_cols = get_by(command)
    bitmask = build_bitmask(command)
    # check that target_column does not exist in dfname
    df2 = gensym()
    sdf = gensym()
    gsdf = gensym()
    RHS = gensym()
    g = gensym()
    #add_special_variables(df2, extract_variable_references(command.arguments[1].args[2]) |> map(x -> x[2]) |> collect)
    quote
        if !($target_column in names($dfname))
            local $df2 = copy($dfname)
            $df2[!, $target_column] .= missing
            local $sdf = view($df2, $bitmask, :)
            if isnothing($by_cols)
                local $RHS = $(replace_variable_references(sdf, command.arguments[1].args[2]) |> vectorize_function_calls)
                $sdf[!, $target_column] .= $RHS
                $df2
            else
                local $gsdf = groupby($sdf, $by_cols)
                for gr in $gsdf
                    local $g = gr
                    local $RHS = $(replace_variable_references(g, command.arguments[1].args[2]) |> vectorize_function_calls)
                    gr[!, $target_column] .= $RHS
                end
                $df2 = combine($gsdf, names($gsdf))
            end
        else
            ArgumentError("Column \"$($target_column)\" already exists in $(names($dfname))") |> throw
        end
    end |> esc
end
