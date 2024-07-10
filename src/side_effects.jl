function rewrite(::Val{:tabulate}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :nofunction])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    columns = [x[1] for x in extract_variable_references.(command.arguments)]
    quote
        $setup
        Kezdi.tabulate($target_df, $columns) |> Kezdi.display_and_return |> $teardown
    end |> esc
end

function rewrite(::Val{:summarize}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :single_argument, :nofunction])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    column = extract_variable_references(command.arguments[1])
    quote
        $setup
        Kezdi.summarize($target_df, $column[1]) |> Kezdi.display_and_return |> $teardown
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
    # validate everything except fixed effects
    to_validate = [x for x in arguments if get_top_symbol(x) != :fe]
    additional_condition = build_bitmask(target_df, :(Kezdi.isvalue($(to_validate...))))
    nobs_to_drop = 
    quote
        $setup
        if sum(.!$additional_condition) > 0
            display("Dropping $(sum(.!$additional_condition)) row(s) due to missing values.")
        end
        if length($(arguments[2:end])) == 1
            reg(view($target_df, $additional_condition, :), @formula($(arguments[1]) ~ $(arguments[2])), $vcov) |> $teardown
        else
            reg(view($target_df, $additional_condition, :), @formula($(arguments[1]) ~ $(Expr(:call, :+, arguments[2:end]...))), $vcov) |> Kezdi.display_and_return |> $teardown
        end
    end |> esc
end

function rewrite(::Val{:count}, command::Command)
    gc = generate_command(command; options=[:ifable, :nofunction], allowed=[])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    quote
        $setup
        Kezdi.counter($target_df) |> Kezdi.display_and_return |> $teardown
    end |> esc
end

function rewrite(::Val{:list}, command::Command)
    gc = generate_command(command; options=[:variables, :ifable, :replace_variables, :vectorize, :assignment], allowed=[:by])
    (; local_copy, target_df, setup, teardown, arguments, options) = gc
    quote
        $setup
        $target_df |> Kezdi.display_and_return |> $teardown
    end |> esc
end

