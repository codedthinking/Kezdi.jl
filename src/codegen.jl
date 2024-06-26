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

function get_by(command::Command)
    options = command.options
    for opt in options
        if opt isa Expr && opt.head == :call && opt.args[1] == :by
            return opt.args[2:end]
        end
    end
end

function get_LHS(expr::Expr)
    LHS, RHS = split_assignment(expr)
    LHS |> extract_variable_references |> first |> String
end

function build_assignment_formula(expr::Expr)
    expr.head == :(=) || error("Expected assignment expression")
    _, RHS = split_assignment(expr)
    LHS = get_LHS(expr)
    RHS = extract_variable_references(RHS) 
    if length(RHS) == 0
        # if no variable is used in RHS of assignment, create an anonymous variable
        columns_to_transform = :(AsTable([]))
        arguments = :_
    else
        columns_to_transform = Expr(:vect, [QuoteNode(x) for x in RHS]...)
        arguments = Expr(:tuple, RHS...)
    end
    target_column = QuoteNode(LHS)
    function_definition = Expr(Symbol("->"), 
        arguments, 
        vectorize_function_calls(expr.args[2]))
    Expr(:call, Symbol("=>"),
        columns_to_transform,
        Expr(:call, Symbol("=>"),
            function_definition,
            target_column
        )
    )
end

function build_bitmask(df::Any, condition::Any)
    if isnothing(condition)
        return :(BitVector(fill(1, nrow($df))))
    end
    @debug "condition: $condition"
    try eval(condition)
        if eval(condition) isa Bool
            @debug "It is Bool"
            return :(BitVector($condition ? fill(1, nrow($df)) : fill(0, nrow($df))))
        end
    catch e 
        replace_variable_references(df, condition) |> vectorize_function_calls
    end
end

build_bitmask(command::Command) = isnothing(command.condition) ? :(BitVector(fill(1, nrow($(command.df))))) : build_bitmask(command.df, command.condition)

function add_special_variables(df::Any, varlist::Vector{Symbol})
    exprs = [] 
    if :_n in varlist
        push!(exprs, :($(df)[!, "_n"] .= 1:nrow($df)))
    end
    if :_N in varlist
        push!(exprs, :($(df)[!, "_N"] .= nrow($df)))
    end
    Expr(:block, exprs...)
end    

function split_assignment(expr::Any)
    if expr isa Expr && expr.head == :(=)
        return (expr.args[1], expr.args[2])
    else
        error("Expected assignment expression, got $expr")
    end
end

function extract_variable_references(expr::Any)
    if is_variable_reference(expr)
        return [expr]
    elseif expr isa Expr
        if is_function_call(expr)
            return vcat(extract_variable_references.(expr.args[2:end])...)
        else
            return vcat(extract_variable_references.(expr.args)...)
        end
    else
        return Symbol[]
    end
end

function replace_variable_references(expr::Any)
    if is_variable_reference(expr)
        return QuoteNode(expr)
    elseif expr isa Expr
        if is_function_call(expr)
            return Expr(expr.head, expr.args[1], replace_variable_references.(expr.args[2:end])...)
        else
            return Expr(expr.head, replace_variable_references.(expr.args)...)
        end
    else
        return expr
    end
end

function replace_variable_references(df::Any, expr::Any)
    if is_variable_reference(expr)
        return Expr(Symbol("."), 
            df,
            QuoteNode(expr))
    elseif expr isa Expr
        if is_function_call(expr)
            return Expr(expr.head, expr.args[1], [replace_variable_references(df, x) for x in expr.args[2:end]]...)
        else
            return Expr(expr.head, [replace_variable_references(df, x) for x in expr.args]...)
        end
    else
        return expr
    end
end

function vectorize_function_calls(expr::Any)
    if expr isa Expr
        if is_function_call(expr)
            vectorized = expr.head == Symbol(".")
            fname = expr.args[1]
            if vectorized
                return Expr(expr.head, fname, vectorize_function_calls.(expr.args[2:end])...)
            elseif fname in DO_NOT_VECTORIZE || (length(methodswith(Vector, eval(fname); supertypes=true)) > 0)
                return Expr(expr.head, fname, 
                    Expr(:call, :skipmissing, 
                    vectorize_function_calls.(expr.args[2:end])...)
                )
            else
                return Expr(Symbol("."), fname,
                    Expr(:tuple,     
                    vectorize_function_calls.(expr.args[2:end])...)
                )
            end
        elseif is_operator(expr.args[1]) && !is_dotted_operator(expr.args[1])
            op = expr.args[1]
            dot_op = Symbol("." * String(op))
            return Expr(expr.head, 
                    dot_op,    
                    vectorize_function_calls.(expr.args[2:end])...)
        else
            return Expr(expr.head, vectorize_function_calls.(expr.args)...)
        end
    else
        return expr
    end
end

is_variable_reference(x::Any) = x isa Symbol && !in(x, RESERVED_WORDS) && !in(x, TYPES) && isalphanumeric(string(x))
is_function_call(x::Any) = x isa Expr && ((x.head == :call && !is_operator(x.args[1]))  || (x.head == Symbol(".") && x.args[1] isa Symbol && x.args[2] isa Expr && x.args[2].head == :tuple)) 

is_operator(x::Any) = x isa Symbol && (in(x, OPERATORS) || is_dotted_operator(x))
is_dotted_operator(x::Any) = x isa Symbol && String(x)[1] == '.' && Symbol(String(x)[2:end]) in OPERATORS

isalphanumeric(c::AbstractChar) = isletter(c) || isdigit(c) || c == '_'
isalphanumeric(str::AbstractString) = all(isalphanumeric, str)
