function generate_command(command::Command; options=[], allowed=[])
    df2 = gensym()
    sdf = gensym()
    gdf = gensym()
    setup = Expr[]
    teardown = Expr[]
    process = (x -> x)
    tdfunction = gensym()
    target_df = df2

    given_options = get_top_symbol.(command.options)

    # check for syntax
    if !(:ifable in options) && !isnothing(command.condition)
        ArgumentError("@if not allowed for this command: $(command.command)") |> throw
    end
    if (:single_argument in options) && length(command.arguments) != 1
        ArgumentError("Exactly one argument is required for this command: @$(command.command)") |> throw
    end
    if (:assignment in options) && !all(isassignment.(command.arguments))
        ArgumentError("@$(command.command) requires an assignment like y = x + 1") |> throw
    end
    if (:nofunction in options) && length(vcat(extract_function_references.(command.arguments)...)) > 0
        ArgumentError("Function calls are not allowed for this command: @$(command.command)") |> throw
    end
    for opt in given_options
        (opt in allowed) || ArgumentError("Invalid option \"$opt\" for this command: @$(command.command)") |> throw
    end

    push!(setup, :(getdf() isa AbstractDataFrame || error("Kezdi.jl commands can only operate on a global DataFrame set by setdf()")))
    push!(setup, :(local $df2 = copy(getdf())))
    variables_condition = (:ifable in options) ? vcat(extract_variable_references(command.condition)...) : Symbol[]
    variables_RHS = (:variables in options) ? vcat(extract_variable_references.(command.arguments)...) : Symbol[]
    if :replace_variables in options
        process(x) = replace_variable_references(sdf, x)
    end
    if :vectorize in options
        process = vectorize_function_calls ∘ process
    end
    if :_n in variables_condition
        push!(setup, :(transform!($df2, eachindex => :_n)))
        push!(teardown, :(select!($df2, Not(:_n))))
    end
    if :_N in variables_condition
        push!(setup, :(transform!($df2, nrow => :_N)))
        push!(teardown, :(select!($df2, Not(:_N))))
    end
    if :ifable in options
        condition = command.condition
        target_df = sdf
        if isnothing(condition)
            push!(setup, :(local $sdf = $df2))
        else
            bitmask = build_bitmask(df2, condition)
            push!(setup, :(local $sdf = view($df2, $bitmask, :)))
        end
    end
    if :by in given_options
        target_df = gdf
        by_cols = get_by(command)
        push!(setup, :(local $gdf = groupby($sdf, $by_cols)))
    end
    if :_n in variables_RHS
        push!(setup, :(transform!($target_df, eachindex => :_n)))
        push!(teardown, :(select!($target_df, Not(:_n))))
    end
    if :_N in variables_RHS
        push!(setup, :(transform!($target_df, nrow => :_N)))
        push!(teardown, :(select!($target_df, Not(:_N))))
    end
    push!(setup, quote
        function $tdfunction(x)
            $(Expr(:block, teardown...))
            x
        end
    end)
    GeneratedCommand(df2, target_df, Expr(:block, setup...), tdfunction, collect(process.(command.arguments)), collect(command.options))
end

get_by(command::Command) = get_option(command, :by)

function get_option(command::Command, key::Symbol)
    options = command.options
    for opt in options
        if opt isa Expr && opt.head == :call && opt.args[1] == key
            return opt.args[2:end]
        end
    end
end


function get_top_symbol(expr::Any)
    if expr isa Expr
        return get_top_symbol(expr.args[1])
    else
        return expr
    end
end

function get_LHS(expr)
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

function build_bitmask(df::Any, condition::Any)::Expr
    condition = condition isa Nothing ? true : condition
    mask = replace_variable_references(df, condition) |> vectorize_function_calls
    bitvector = :(falses(nrow($(df))))
    :($bitvector .| ($mask))
end

build_bitmask(command::Command) = isnothing(command.condition) ? :(trues(nrow($(command.df)))) : build_bitmask(command.df, command.condition)

function split_assignment(expr::Any)
    if isassignment(expr)
        return (expr.args[1], expr.args[2])
    else
        ArgumentError("Expected assignment expression, got $expr") |> throw
    end
end

function extract_function_references(expr::Any)
    if is_function_call(expr) || (expr isa Expr && expr.head == :call && is_operator(expr.args[1]))
        return vcat([expr.args[1]], extract_function_references.(expr.args[2:end])...)
    elseif expr isa Expr
        return vcat(extract_function_references.(expr.args)...)
    else
        return Symbol[]
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
            elseif fname == :DNV
                return expr.args[2]
            elseif fname in DO_NOT_VECTORIZE || (!(fname in ALWAYS_VECTORIZE) && (length(methodswith(Vector, eval(fname); supertypes=true)) > 0))
                return Expr(expr.head, fname, 
                Expr(:call, :collect, 
                Expr(:call, :skipmissing, 
                    vectorize_function_calls.(expr.args[2:end])...)
                ))
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

function get_dot_parts(ex::Expr)
    is_dot_reference(ex) || error("Expected a dot reference, got $ex")
    parts = []
    while is_dot_reference(ex)
        push!(parts, ex.args[2].value)
        ex = ex.args[1]
    end
    push!(parts, ex)
    reverse(parts)
end

is_variable_reference(x::Any) = x isa Symbol && !in(x, RESERVED_WORDS) && !in(x, TYPES) && isalphanumeric(string(x))
is_function_call(x::Any) = x isa Expr && ((x.head == :call && !is_operator(x.args[1]))  || (x.head == Symbol(".") && x.args[1] isa Symbol && x.args[2] isa Expr && x.args[2].head == :tuple)) 

is_operator(x::Any) = x isa Symbol && (in(x, OPERATORS) || is_dotted_operator(x))
is_dotted_operator(x::Any) = x isa Symbol && String(x)[1] == '.' && Symbol(String(x)[2:end]) in OPERATORS

is_dot_reference(x) = false
function is_dot_reference(e::Expr)
    e.head == :. &&
        length(e.args) == 2 &&
        (e.args[1] isa Symbol || is_dot_reference(e.args[1])) &&
        e.args[2] isa QuoteNode &&
        e.args[2].value isa Symbol
end

isalphanumeric(c::AbstractChar) = isletter(c) || isdigit(c) || c == '_'
isalphanumeric(str::AbstractString) = all(isalphanumeric, str)

isassignment(expr::Any) = expr isa Expr && expr.head == :(=) && length(expr.args) == 2

# only broadcast first argument. For example, [1, 2, 3] in [2, 3] should evaluate to [false, true, true]
BFA(f::Function, xs, args...; kwargs...) = broadcast(x -> f(x, args...; kwargs...), xs)
