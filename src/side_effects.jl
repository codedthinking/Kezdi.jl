function rewrite(::Val{:tabulate}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    columns = [x[1] for x in extract_variable_references.(command.arguments)]
    quote
        $setup
        Kezdi.tabulate($target_df, $columns) |> $teardown
    end |> esc
end

function rewrite(::Val{:summarize}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :single_argument, :nofunction])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    column = extract_variable_references(command.arguments[1])
    quote
        $setup
        Kezdi.summarize($target_df, $column[1]) |> $teardown
    end |> esc
end

function rewrite(::Val{:regress}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable], allowed=[:robust, :cluster])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
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

function rewrite(::Val{:count}, command::Command)
    gc = generate_command(command; options=[:ifable, :nofunction], allowed=[:by])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    quote
        $setup
        Kezdi.counter($target_df) |> $teardown
    end |> esc
end

