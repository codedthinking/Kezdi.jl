# use multiple dispatch to generate code 
rewrite(command::Command) = rewrite(Val(command.command), command)

function rewrite(::Val{:tabulate}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    columns = [x[1] for x in extract_variable_references.(command.arguments)]
    quote
        $setup
        Kezdi.tabulate($target_df, $columns) |> $teardown
    end |> esc
end

function rewrite(::Val{:summarize}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :single_argument, :nofunction])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    column = extract_variable_references(command.arguments[1])
    quote
        $setup
        Kezdi.summarize($target_df, $column[1]) |> $teardown
    end |> esc
end

function rewrite(::Val{:regress}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable], allowed=[:robust, :cluster])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
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
            reg($target_df, @formula($(arguments[1]) ~ $(arguments[2])), $vcov) |> $teardown
        else
            reg($target_df, @formula($(arguments[1]) ~ $(Expr(:call, :+, arguments[2:end]...))), $vcov) |> $teardown
        end
    end |> esc
end

function rewrite(::Val{:generate}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    LHS, RHS = split_assignment(arguments[1])
    quote
        if ($target_column in names($df))
            ArgumentError("Column \"$($target_column)\" already exists in $(names($df))") |> throw
        else
            $setup
            $local_copy[!, $target_column] .= missing
            $target_df[!, $target_column] .= $RHS
            $local_copy |> $teardown
        end
    end |> esc
end

function rewrite(::Val{:replace}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    LHS, RHS = split_assignment(arguments[1])
    third_vector = gensym()
    bitmask = build_bitmask(local_copy, vectorize_function_calls(replace_variable_references(local_copy, command.condition)))
    quote
        if !($target_column in names($df))
            ArgumentError("Column \"$($target_column)\" does not exist in $(names($df))") |> throw
        else
            $setup
            if eltype($RHS) != eltype($target_df[!, $target_column])
                local $third_vector = Vector{eltype($RHS)}(undef, nrow($local_copy))
                $third_vector[$bitmask] .= $RHS
                $third_vector[.!$bitmask] .= $local_copy[!, $target_column][.!$bitmask]
                $local_copy[!, $target_column] = $third_vector
            else
                $target_df[!, $target_column] .= $RHS
            end
            $local_copy |> $teardown
        end
    end |> esc
end

function rewrite(::Val{:keep}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    quote
        $setup
        $target_df[!, isempty($(command.arguments)) ? eval(:(:)) : collect($command.arguments)]  |> $teardown
    end |> esc
end

function rewrite(::Val{:drop}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
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
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    combine_epxression = Expr(:call, :combine, target_df, build_assignment_formula.(command.arguments)...)
    quote
        $setup
        $combine_epxression |> $teardown
    end |> esc
end

function rewrite(::Val{:egen}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    transform_expression = Expr(:call, :transform!, target_df, build_assignment_formula.(command.arguments)...)
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

function rewrite(::Val{:count}, command::Command)
    gc = generate_command(command; options=[:ifable, :nofunction], allowed=[:by])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    quote
        $setup
        Kezdi.counter($target_df) |> $teardown
    end |> esc
end

function rewrite(::Val{:sort}, command::Command)
    gc = generate_command(command; options=[:variables, :nofunction], allowed=[:desc])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    columns = [x[1] for x in extract_variable_references.(command.arguments)]
    if :desc in get_top_symbol.(options)
        desc = true
    else
        desc = false
    end
    quote
        $setup
        sort($target_df, $columns, rev=$desc) |> $teardown
    end |> esc
end

function rewrite(::Val{:order}, command::Command)
    gc = generate_command(command; allowed=[:desc])
    (; df, local_copy, target_df, setup, teardown, arguments, options) = gc
    columns = [x[1] for x in extract_variable_references.(command.arguments)]
    if :desc in get_top_symbol.(options)
        desc = true
    else
        desc = false
    end
    quote
        $setup
        cols = sort(names($target_df), rev=$desc)
        $target_df[!,cols]|> $teardown
    end |> esc
end