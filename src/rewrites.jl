# use multiple dispatch to generate code 
rewrite(command::Command) = rewrite(Val(command.command), command)

function rewrite(::Val{:summarize}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :single_argument])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    column = extract_variable_references(command.arguments[1])
    s = gensym()
    quote
        $setup
        local $s = Kezdi.summarize($sdf, $column[1])
        $teardown
        $s
    end |> esc
end

function rewrite(::Val{:regress}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    r = gensym()
    quote
        $setup
        local $r = reg($sdf, @formula $(arguments[1]) ~ $(sum(arguments[2:end])))
        $teardown
        $r
    end |> esc
end

function rewrite(::Val{:generate}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    target_column = get_LHS(command.arguments[1])
    LHS, RHS = split_assignment(arguments[1])
    quote
        if ($target_column in names($df))
            ArgumentError("Column \"$($target_column)\" already exists in $(names($df))") |> throw
        else
            $setup
            $local_copy[!, $target_column] .= missing
            $sdf[!, $target_column] .= $RHS
            $teardown
            $local_copy
        end
    end |> esc
end

function rewrite(::Val{:replace}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    target_column = get_LHS(command.arguments[1])
    LHS, RHS = split_assignment(arguments[1])
    third_vector = gensym()
    bitmask = build_bitmask(local_copy, vectorize_function_calls(replace_variable_references(local_copy, command.condition)))
    quote
        if !($target_column in names($df))
            ArgumentError("Column \"$($target_column)\" does not exist in $(names($df))") |> throw
        else
            $setup
            if eltype($RHS) != eltype($sdf[!, $target_column])
                local $third_vector = Vector{eltype($RHS)}(undef, nrow($local_copy))
                $third_vector[$bitmask] .= $RHS
                $third_vector[.!$bitmask] .= $local_copy[!, $target_column][.!$bitmask]
                $local_copy[!, $target_column] = $third_vector
            else
                $sdf[!, $target_column] .= $RHS
            end
            $teardown
            $local_copy
        end
    end |> esc
end

function rewrite(::Val{:collapse}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    by_cols = get_by(command)
    if isnothing(by_cols)
        combine_epxression = Expr(:call, :combine, sdf, build_assignment_formula.(command.arguments)...)
    else
        combine_epxression = Expr(:call, :combine, gdf, build_assignment_formula.(command.arguments)...)
    end
    quote
        $setup
        if isnothing($by_cols)
            $combine_epxression
        else
            local $gdf = groupby($sdf, $by_cols)
            $combine_epxression
        end
    end |> esc
end

function rewrite(::Val{:keep}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    output = gensym()
    quote
        $setup
        local $output = $sdf[!, isempty($(command.arguments)) ? eval(:(:)) : collect($command.arguments)]
        $teardown
        $output
    end |> esc
end

function rewrite(::Val{:drop}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    if isnothing(command.condition)
        return quote
            $setup
            select($local_copy, Not(collect($(command.arguments))))
        end |> esc
    end 
    bitmask = build_bitmask(local_copy, :(!($command.condition)))
    return quote
        $setup
        $local_copy[$bitmask, :]
    end |> esc
end

function rewrite(::Val{:egen}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments) = gc
    target_column = get_LHS(command.arguments[1])
    by_cols = get_by(command)
    RHS = gensym()
    g = gensym()
    quote
        if ($target_column in names($df))
            ArgumentError("Column \"$($target_column)\" already exists in $(names($df))") |> throw
        else
            $setup
            $local_copy[!, $target_column] .= missing
            if isnothing($by_cols)
                local $RHS = $(replace_variable_references(sdf, command.arguments[1].args[2]) |> vectorize_function_calls)
                $sdf[!, $target_column] .= $RHS
                $local_copy
            else
                local $gdf = groupby($sdf, $by_cols)
                for i in $gdf
                    local $g = i
                    local $RHS = $(replace_variable_references(g, command.arguments[1].args[2]) |> vectorize_function_calls)
                    $g[!, $target_column] .= $RHS
                end
                $local_copy = combine($gdf, names($gdf))
            end
        end
    end |> esc
end
