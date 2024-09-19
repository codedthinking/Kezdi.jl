function generate_command(command::Command; options=[], allowed=[])
    df2 = gensym()
    sdf = gensym()
    gdf = gensym()
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
    if (:nofunction in options) && any(isfunctioncall.(command.arguments))
        ArgumentError("Function calls are not allowed for this command: @$(command.command)") |> throw
    end
    for opt in given_options
        (opt in allowed) || ArgumentError("Invalid option \"$opt\" for this command: @$(command.command)") |> throw
    end

    push!(setup, :(println("$(Kezdi.prompt())$($(string(command)))\n")))
    push!(setup, :(getdf() isa AbstractDataFrame || error("Kezdi.jl commands can only operate on a global DataFrame set by setdf()")))
    push!(setup, :(local $df2 = Kezdi._global_dataframe))
    variables_condition = (:ifable in options) ? vcat(extract_column_references(command.condition)...) : Symbol[]
    variables_RHS = (:variables in options) ? vcat(extract_column_references.(command.arguments)...) : Symbol[]
    variables = vcat(variables_condition, variables_RHS)
    if :replace_variables in options
        process(x) = replace_column_references(sdf, x)
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
    push!(setup, :(function $tdfunction(x)
            $(Expr(:block, teardown...))
            x
        end))
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

get_top_symbol(expr::Any) = expr
get_top_symbol(expr::Expr) = get_top_symbol(expr.args[1])

function get_LHS(expr)
    LHS, RHS = split_assignment(expr)
    LHS |> extract_column_references |> first |> String
end

function build_assignment_formula(expr::Expr)
    expr.head == :(=) || error("Expected assignment expression")
    _, RHS = split_assignment(expr)
    LHS = get_LHS(expr)
    RHS = extract_column_references(RHS) 
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
    mask = replace_column_references(df, condition) |> vectorize_function_calls
    :(falses(nrow($(df))) .| Missings.replace($mask, false))
end

build_bitmask(command::Command) = isnothing(command.condition) ? :(trues(nrow($(command.df)))) : build_bitmask(command.df, command.condition)

function split_assignment(expr::Any)
    isassignment(expr) || (ArgumentError("Expected assignment expression, got $expr") |> throw)
    (expr.args[1], expr.args[2])
end

extract_column_references(::Any) = Symbol[]
extract_column_references(expr::Symbol) = iscolreference(expr) ? [expr] : Symbol[]
function extract_column_references(expr::Expr)
    # Main.x is a variable reference, not a column reference
    isvarreference(expr) && return Symbol[]
    isfunctioncall(expr) ? 
        vcat(extract_column_references.(expr.args[2:end])...) : 
        vcat(extract_column_references.(expr.args)...)
end

replace_column_references(expr::Any) = expr
replace_column_references(expr::Symbol) = iscolreference(expr) ? QuoteNode(expr) : expr
function replace_column_references(expr::Expr)
    # Main.x is a variable reference, not a column reference
    isvarreference(expr) && return expr
    isfunctioncall(expr) && !is_operator(expr.head) && return Expr(expr.head, expr.args[1], replace_column_references.(expr.args[2:end])...)  
    Expr(expr.head, replace_column_references.(expr.args)...)
end

replace_column_references(df::Any, expr::Any) = expr
replace_column_references(df::Any, expr::Symbol) = iscolreference(expr) ? Expr(:., df, QuoteNode(expr)) : expr
function replace_column_references(df::Any, expr::Expr)
    # Main.x is a variable reference, not a column reference
    isvarreference(expr) && return expr
    isfunctioncall(expr) && !is_operator(expr.head) && return Expr(expr.head, expr.args[1], [replace_column_references(df, x) for x in expr.args[2:end]]...)
    Expr(expr.head, [replace_column_references(df, x) for x in expr.args]...)
end

tovectorize(::Any) = false
tovectorize(expr::Symbol) = Base.isoperator(expr) && !is_dotted_operator(expr)
function tovectorize(expr::Expr)
    isfunctioncall(expr) || return false
    fname = expr.args[1]
    expr.head == Symbol(".") && return false
    is_dotted_operator(expr.head) && return false
    is_dotted_operator(fname) && return false
    fname in DO_NOT_VECTORIZE && return false
    fname == :~ && return false
    is_operator(expr.head) && return true
    is_operator(fname) && return true
    fname in ALWAYS_VECTORIZE && return true
    operates_on_vector(fname) && return false
    return true
end

vectorize_function_calls(expr::Any) = expr
function vectorize_function_calls(expr::Expr)
    isfunctioncall(expr) || return Expr(expr.head, vectorize_function_calls.(expr.args)...)
    fname = expr.args[1]
    # x && y is not a function call, becomes x .&& y
    is_operator(expr.head) && tovectorize(expr) && expr.head in SYNTACTIC_OPERATORS && 
        return Expr(Symbol("." * String(expr.head)), vectorize_function_calls.(expr.args)...) 
    # x + y is not a function call, becomes x .+ y
    is_operator(fname) && tovectorize(expr) &&
        return Expr(expr.head, Symbol("." * String(fname)), vectorize_function_calls.(expr.args[2:end])...)
    # f(x) becomes f.(x) or passmissing(f).(x)
    tovectorize(expr) && return operates_on_missing(fname) ? 
        Expr(Symbol("."), fname,
            Expr(:tuple,   
            vectorize_function_calls.(expr.args[2:end])...)
        ) :
        Expr(Symbol("."), :(passmissing($fname)),
            Expr(:tuple,   
            vectorize_function_calls.(expr.args[2:end])...)
        )
    # ~f(x) becomes f(x), not vectorized
    fname == :~ && return Expr(expr.args[2].head, expr.args[2].args[1], vectorize_function_calls.(expr.args[2].args[2:end])...)
    # this is already vectorized, do not touch
    expr.head == Symbol(".") &&     return Expr(expr.head, vectorize_function_calls.(expr.args)...)
    # remaining function calls are not vectorized
    return Expr(expr.head, fname, [Expr(:call, :keep_only_values, vectorize_function_calls(arg)) for arg in expr.args[2:end]]...)
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

is_operator(::Any) = false
is_operator(x::Symbol) = Base.isoperator(x) && x != :.
is_dotted_operator(::Any) = false
is_dotted_operator(x::Symbol) = is_operator(x) && String(x)[1] == '.'

is_dot_reference(::Any) = false
is_dot_reference(e::Expr) = Base.isexpr(e, :., 2) &&
        (e.args[1] isa Symbol || is_dot_reference(e.args[1])) &&
        e.args[2] isa QuoteNode &&
        e.args[2].value isa Symbol

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

isvarreference(x::Symbol) = Meta.isidentifier(x) && !in(x, RESERVED_WORDS) && !in(x, TYPES)
isvarreference(::Any) = false
isvarreference(ex::Expr) = 
    Meta.isexpr(ex, :ref) || 
    (Meta.isexpr(ex, :., 2) && 
        ((ex.args[1] isa Symbol && isvarreference(ex.args[2])) ||
         (ex.args[2] isa QuoteNode && isvarreference(ex.args[2].value))))

iscolreference(::Any) = false
iscolreference(x::Symbol) = isvarreference(x) && !in(x, RESERVED_WORDS) && !in(x, TYPES)

isfunctioncall(::Any) = false
isfunctioncall(x::Symbol) = is_operator(x)
#=
isfunctioncall(ex::Expr) = 
    Meta.isexpr(ex, :call) ||  # This covers both f(x) and x+y
    (Meta.isexpr(ex, :., 2) && ex.args[1] isa Symbol && 
     (Meta.isexpr(ex.args[2], :tuple) || Meta.isexpr(ex.args[2], :call)) && 
     isfunctioncall(ex.args[end])) ||
    Meta.isexpr(ex, :., 3)  # Vectorized function call (broadcasting)
=#
isfunctioncall(x::Expr) = x.head == :call || (x.head == Symbol(".") && x.args[1] isa Symbol && x.args[2] isa Expr && x.args[2].head == :tuple) || x.head in SYNTACTIC_OPERATORS

add_skipmissing(expr::Any) = expr
function add_skipmissing(expr::Expr)
    if expr.head == Symbol(".") && expr.args[2] isa QuoteNode
        return Expr(:call, :skipmissing, expr)
    end
    Expr(expr.head, expr.args[1], [add_skipmissing(x) for x in expr.args[2:end]]...)
end