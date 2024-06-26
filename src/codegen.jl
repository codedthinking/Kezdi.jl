function generate_command(command::Command; options=[])
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
    condition = condition isa Nothing ? true : condition
    mask = replace_variable_references(df, condition) |> vectorize_function_calls
    bitvector = :(BitVector(zeros(Bool, nrow($(df)))))
    :($bitvector .|= $mask)
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
