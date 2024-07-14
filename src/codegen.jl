function generate_command(command::Command; options=[], allowed=[])
    df2 = gensym()
    sdf = gensym()
    gdf = gensym()
    context = gensym()
    setup = Expr[]
    teardown = Expr[]
    process = (x -> x)
    tdfunction = gensym()
    # this points to the DataFrame that the command will return to the user
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

    push!(setup, quote
        local $context = Kezdi.get_runtime_context()
        $context.df isa AbstractDataFrame || error("Kezdi.jl commands can only operate on a DataFrame")
        local $df2 = copy($context.df)
    end)
    variables_condition = (:ifable in options) ? vcat(extract_variable_references(command.condition)...) : Symbol[]
    variables_RHS = (:variables in options) ? vcat(extract_variable_references.(command.arguments)...) : Symbol[]
    variables = vcat(variables_condition, variables_RHS)
    if :replace_variables in options
        process(x) = replace_variable_references(sdf, x)
    end
    if :vectorize in options
        process = vectorize_function_calls ∘ process
    end
    # where should special variables be created?
    # when grouped by, then couting rows should be done on the grouped data
    _n_goes_to = df2
    if :by in given_options && (:_n in variables || :_N in variables)
        by_cols = get_by(command)
        _n_goes_to = :(groupby($df2, $by_cols))
    end
    if :_n in variables
        push!(setup, :(transform!($_n_goes_to, eachindex => :_n)))
        push!(teardown, :(select!($df2, Not(:_n))))
    end
    if :_N in variables
        push!(setup, :(transform!($_n_goes_to, nrow => :_N)))
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
    push!(setup, quote
        function $tdfunction(x)
            # add global dataframe save here
            $context.inplace && setdf($target_df)
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
    :(falses(nrow($(df))) .| Missings.replace($mask, false))
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
                return operates_on_missing(fname) ? 
                    Expr(expr.head, fname, vectorize_function_calls.(expr.args[2:end])...) : 
                    Expr(expr.head, :(passmissing($fname)), vectorize_function_calls.(expr.args[2:end])...) 
            elseif fname == :DNV
                return expr.args[2]
            elseif fname in DO_NOT_VECTORIZE || (!(fname in ALWAYS_VECTORIZE) && operates_on_vector(fname))
                skipmissing_each_arg = [Expr(:call, :keep_only_values, vectorize_function_calls(arg)) for arg in expr.args[2:end]]
                return Expr(expr.head, fname, skipmissing_each_arg...)
            else
                return operates_on_missing(fname) ? 
                    Expr(Symbol("."), fname,
                        Expr(:tuple,   
                        vectorize_function_calls.(expr.args[2:end])...)
                    ) :
                    Expr(Symbol("."), :(passmissing($fname)),
                        Expr(:tuple,   
                        vectorize_function_calls.(expr.args[2:end])...)
                    )
            end
        elseif is_operator(expr.head) && !is_dotted_operator(expr.head) && expr.head in SYNTACTIC_OPERATORS
            # special handling of syntactic operators like &&, ||, etc. 
            # these are not called as a function
            op = expr.head
            dot_op = Symbol("." * String(op))
            return Expr(dot_op,    
                    vectorize_function_calls.(expr.args)...)
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

get_dot_parts(ex::Symbol) = [ex]
function get_dot_parts(ex::Expr)
    is_dot_reference(ex) || error("Expected a dot reference, got $ex")
    parts = Symbol[]
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
operates_on_missing(expr::Any) = (expr isa Symbol && expr == :ismissing) || operates_on_type(expr, Missing)
operates_on_vector(expr::Any) = operates_on_type(expr, Vector)

function operates_on_type(expr::Any, T::Type)
    try
        return length(methodswith(T, Main.eval(expr); supertypes=true)) > 0
    catch ee
        !isa(ee, UndefVarError) && rethrow(ee)
        return false
    end
end
