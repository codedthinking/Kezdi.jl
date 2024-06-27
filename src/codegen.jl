function generate_command(command::Command; options=[])
    dfname = command.df
    df2 = gensym()
    sdf = gensym()
    setup = Expr[]
    teardown = Expr[]
    process = (x -> x)
    tdfunction = gensym()

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

    push!(setup, :($dfname isa AbstractDataFrame || error("Expected DataFrame as first argument")))
    push!(setup, :(local $df2 = copy($dfname)))
    if :variables in options
        if :ifable in options
            variables = vcat(extract_variable_references.(command.arguments)..., extract_variable_references(command.condition)...)
        else
            variables = vcat(extract_variable_references.(command.arguments)...)
        end
    else
        variables = Symbol[]
    end
    if :replace_variables in options
        process(x) = replace_variable_references(sdf, x)
    end
    if :vectorize in options
        process = vectorize_function_calls ∘ process
    end
    if :_n in variables
        push!(setup, :($(df2)[!, "_n"] .= 1:nrow($df2)))
        push!(teardown, :(select!($df2, Not(:_n))))
    end
    if :_N in variables
        push!(setup, :($(df2)[!, "_N"] .= nrow($df2)))
        push!(teardown, :(select!($df2, Not(:_N))))
    end
    if :ifable in options
        condition = vectorize_function_calls(replace_variable_references(df2, command.condition))
        if isnothing(condition)
            push!(setup, :(local $sdf = $df2))
        else
            bitmask = build_bitmask(df2, condition)
            push!(setup, :(local $sdf = view($df2, $bitmask, :)))
        end
    end
    push!(setup, quote
        function $tdfunction(x)
            $(Expr(:block, teardown...))
            x
        end
    end)
    GeneratedCommand(dfname, df2, sdf, gensym(), Expr(:block, setup...), tdfunction, collect(process.(command.arguments)))
end

function get_by(command::Command)
    options = command.options
    for opt in options
        if opt isa Expr && opt.head == :call && opt.args[1] == :by
            return opt.args[2:end]
        end
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
    bitvector = :(BitVector(zeros(Bool, nrow($(df)))))
    :($bitvector .| ($mask))
end

build_bitmask(command::Command) = isnothing(command.condition) ? :(BitVector(fill(1, nrow($(command.df))))) : build_bitmask(command.df, command.condition)

function split_assignment(expr::Any)
    if isassignment(expr)
        return (expr.args[1], expr.args[2])
    else
        ArgumentError("Expected assignment expression, got $expr") |> throw
    end
end

function extract_function_references(expr::Any)
    if is_function_call(expr)
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
            elseif fname in DO_NOT_VECTORIZE || (!(fname in OPERATORS) && (length(methodswith(Vector, eval(fname); supertypes=true)) > 0))
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
is_function_call(x::Any) = x isa Expr && ((x.head == :call)  || (x.head == Symbol(".") && x.args[1] isa Symbol && x.args[2] isa Expr && x.args[2].head == :tuple)) 

is_operator(x::Any) = x isa Symbol && (in(x, OPERATORS) || is_dotted_operator(x))
is_dotted_operator(x::Any) = x isa Symbol && String(x)[1] == '.' && Symbol(String(x)[2:end]) in OPERATORS

isalphanumeric(c::AbstractChar) = isletter(c) || isdigit(c) || c == '_'
isalphanumeric(str::AbstractString) = all(isalphanumeric, str)

isassignment(expr::Any) = expr isa Expr && expr.head == :(=) && length(expr.args) == 2

# this is to be deleted after refactoring
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