# use multiple dispatch to generate code 
rewrite(command::Command) = rewrite(Val(command.command), command)

function rewrite(::Val{:tabulate}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    columns = [x[1] for x in extract_variable_references.(command.arguments)]
    quote
        $setup
        Kezdi.tabulate($sdf, $columns) |> $teardown
    end |> esc
end

function rewrite(::Val{:summarize}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :single_argument, :nofunction])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    column = extract_variable_references(command.arguments[1])
    quote
        $setup
        Kezdi.summarize($sdf, $column[1]) |> $teardown
    end |> esc
end

function rewrite(::Val{:regress}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable], allowed=[:robust, :cluster])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    if :robust in get_top_symbol.(options)
        vcov = :(Vcov.robust())
    elseif :cluster in get_top_symbol.(options)
        vars = get_option(command, :cluster)
        vars = replace_variable_references.(vars)
        vcov = :(Vcov.cluster($(vars...)))
    else
        vcov = :(Vcov.simple())
    end
    quote
        $setup
        if length($(arguments[2:end])) == 1
            reg($sdf, @formula($(arguments[1]) ~ $(arguments[2])), $vcov) |> $teardown
        else
            reg($sdf, @formula($(arguments[1]) ~ $(Expr(:call, :+, arguments[2:end]...))), $vcov) |> $teardown
        end
    end |> esc
end

function rewrite(::Val{:generate}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    LHS, RHS = split_assignment(arguments[1])
    quote
        if ($target_column in names($df))
            ArgumentError("Column \"$($target_column)\" already exists in $(names($df))") |> throw
        else
            $setup
            $local_copy[!, $target_column] .= missing
            $sdf[!, $target_column] .= $RHS
            $local_copy |> $teardown
        end
    end |> esc
end

function rewrite(::Val{:replace}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
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
            $local_copy |> $teardown
        end
    end |> esc
end

function rewrite(::Val{:keep}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    quote
        $setup
        $sdf[!, isempty($(command.arguments)) ? eval(:(:)) : collect($command.arguments)]  |> $teardown
    end |> esc
end

function rewrite(::Val{:drop}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    if isnothing(command.condition)
        return quote
            $setup
            select($local_copy, Not(collect($(command.arguments)))) |> $teardown
        end |> esc
    end 
    bitmask = build_bitmask(local_copy, command.condition)
    return quote
        $setup
        $local_copy[Kezdi.BFA(!, $bitmask), :] |> $teardown
    end |> esc
end

function rewrite(::Val{:collapse}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    by_cols = get_by(command)
    if isnothing(by_cols)
        combine_epxression = Expr(:call, :combine, sdf, build_assignment_formula.(command.arguments)...)
    else
        combine_epxression = Expr(:call, :combine, gdf, build_assignment_formula.(command.arguments)...)
    end
    quote
        $setup
        $combine_epxression |> $teardown
    end |> esc
end

function rewrite(::Val{:egen}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; df, local_copy, sdf, gdf, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    by_cols = get_by(command)
    if isnothing(by_cols)
        transform_expression = Expr(:call, :transform!, sdf, build_assignment_formula.(command.arguments)...)
    else
        transform_expression = Expr(:call, :transform!, gdf, build_assignment_formula.(command.arguments)...)
    end
    quote
        if ($target_column in names($df))
            ArgumentError("Column \"$($target_column)\" already exists in $(names($df))") |> throw
        else
            $setup
            $transform_expression
            $local_copy |> $teardown
        end
    end |> esc
end
