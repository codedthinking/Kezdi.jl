# use multiple dispatch to generate code 
rewrite(command::Command) = rewrite(Val(command.command), command)

function rewrite(::Val{:rename}, command::Command)
    gc = generate_command(command; options=[:variables], allowed=[])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    quote
        (length($arguments) != 2) && ArgumentError("Syntax is @rename oldname newname") |> throw
        $setup
        rename!($local_copy, $arguments[1] => $arguments[2]) |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:generate}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    LHS, RHS = split_assignment(arguments[1])
    quote
        ($target_column in names(getdf())) && ArgumentError("Column \"$($target_column)\" already exists in $(names(getdf()))") |> throw
        $setup
        $local_copy[!, $target_column] .= missing
        $target_df[!, $target_column] .= $RHS
        $local_copy |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:replace}, command::Command)
    gc = generate_command(command; options=[:single_argument, :variables, :ifable, :replace_variables, :vectorize, :assignment])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    LHS, RHS = split_assignment(arguments[1])
    third_vector = gensym()
    eltype_LHS = gensym()
    eltype_RHS = gensym()
    bitmask = build_bitmask(local_copy, command.condition)
    quote
        !($target_column in names(getdf())) && ArgumentError("Column \"$($target_column)\" does not exist in $(names(getdf()))") |> throw
        $setup
        $eltype_RHS = $RHS isa AbstractVector ? eltype($RHS) : typeof($RHS)
        $eltype_LHS = eltype($local_copy[.!$bitmask, $target_column])
        if $eltype_RHS != $eltype_LHS
            local $third_vector = Vector{promote_type($eltype_LHS, $eltype_RHS)}(undef, nrow($local_copy))
            $third_vector[$bitmask] .= $RHS
            $third_vector[.!($bitmask)] .= $local_copy[.!($bitmask), $target_column]
            $local_copy[!, $target_column] = $third_vector
        else
            $target_df[!, $target_column] .= $RHS
        end
        $local_copy |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:keep}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    cols = isempty(command.arguments) ? :(:) : :(collect($command.arguments))
    quote
        $setup
        $target_df[!, $cols]  |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:drop}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    if isnothing(command.condition)
        return quote
            $setup
            select($local_copy, Not(collect($(command.arguments)))) |> $teardown |> setdf
        end |> esc
    end 
    bitmask = build_bitmask(local_copy, command.condition)
    return quote
        $setup
        $local_copy[.!($bitmask), :] |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:collapse}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    combine_epxression = Expr(:call, :combine, target_df, build_assignment_formula.(command.arguments)...)
    quote
        $setup
        $combine_epxression |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:egen}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    target_column = get_LHS(command.arguments[1])
    transform_expression = Expr(:call, :transform!, target_df, build_assignment_formula.(command.arguments)...)
    quote
        ($target_column in names(getdf())) && ArgumentError("Column \"$($target_column)\" already exists in $(names(getdf()))") |> throw
        $setup
        $transform_expression
        $local_copy |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:sort}, command::Command)
    gc = generate_command(command; options=[:variables, :nofunction], allowed=[:desc])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    columns = [x[1] for x in extract_column_references.(command.arguments)]
    desc = :desc in get_top_symbol.(options) ? true : false
    quote
        $setup
        sort($target_df, $columns, rev=$desc) |> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:order}, command::Command)
    gc = generate_command(command; options = [:variables, :nofunction], allowed=[:desc, :last, :after, :before , :alphabetical])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    desc = :desc in get_top_symbol.(options)
    last = :last in get_top_symbol.(options)
    after = :after in get_top_symbol.(options)
    before = :before in get_top_symbol.(options)
    alphabetical = :alphabetical in get_top_symbol.(options)

    if before && after
        ArgumentError("Cannot use both `before` and `after` options in @order") |> throw
    end
    if last && (before || after)
        ArgumentError("Cannot use `last` with `before` or `after` options in @order") |> throw
    end
    if desc && !alphabetical
        ArgumentError("Cannot use `desc` without `alphabetical` option in @order") |> throw
    end
    
    if before
        var = get_option(command, :before)
    elseif after
        var = get_option(command, :after)
    else
        var = nothing
    end

    if !isnothing(var) && length(var) > 1
        ArgumentError("Only one variable can be specified for `before` or `after` options in @order") |> throw
    end

    target_cols = :(collect($(command.arguments)))
    cols = gensym()
    idx = gensym()

    quote
        $setup
        $cols = [Symbol(col) for col in names($target_df) if Symbol(col) ∉ $target_cols]
        if $alphabetical
            $cols = sort($cols, rev = $desc)
        end

        if $after
            $idx = findfirst(x -> x == $var[1], $cols)
            for (i, col) in enumerate($target_cols)
                insert!($cols, $idx + i, col)
            end
        end

        if $before
            $idx = findfirst(x -> x == $var[1], $cols)
            for (i, col) in enumerate($target_cols)
                insert!($cols, $idx + i - 1, col)
            end
        end

        if $last && !($after || $before)
            $cols = push!($cols, $target_cols...)
        elseif !($after || $before)
            $cols = pushfirst!($cols, $target_cols...)
        end

        $target_df[!, $cols]|> $teardown |> setdf
    end |> esc
end

function rewrite(::Val{:mvencode}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction], allowed=[:mv])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    cols = :(collect($command.arguments))
    value = isnothing(get_option(command, :mv)) ? missing : get_option(command, :mv)[1]
    value isa AbstractVector && ArgumentError("The value for @mvencode cannot be a vector") |> throw
    bitmask = build_bitmask(local_copy, command.condition)
    third_vector = gensym()
    valtype = gensym()
    coltype = gensym()
    quote
        $setup
        $valtype = typeof($value)        
        for col in $cols
            $coltype = eltype($local_copy[.!($bitmask), col])
            if $valtype != $coltype
                local $third_vector = Vector{promote_type($coltype, $valtype)}($local_copy[!, col])
                $local_copy[!, col] = $third_vector
            end
        end
        $local_copy[$bitmask, $cols] = mvreplace.($local_copy[$bitmask, $cols], $value)
        $local_copy |> $teardown |> setdf
    end |> esc
end