# use multiple dispatch to generate code 
rewrite(command::Command) = rewrite(Val(command.command), command)

function rewrite(::Val{:generate}, command::Command)
    dfname = command.df
    formula = build_assignment_formula(command.arguments[1])
    esc(:(transform($dfname, $formula)))
end

function rewrite(::Val{:replace}, command::Command)
    dfname = command.df
    formula = build_assignment_formula(command.arguments[1])
    esc(:(transform($dfname, $formula)))
end

function rewrite(::Val{:egen}, command::Command)
    dfname = command.df
    formula = build_assignment_formula(command.arguments[1])
    esc(:(transform($dfname, $formula)))
end

function build_assignment_formula(expr::Expr)
    expr.head == :(=) || error("Expected assignment expression")
    vars = extract_variable_references(expr)
    @debug vars
    LHS = [y[2] for y in vars if y[1] == :LHS][1]
    RHS = [y[2] for y in vars if y[1] == :RHS]
    @debug LHS
    @debug RHS
    if length(RHS) == 0
        # if no variable is used in RHS of assignment, create an anonymous variable
        columns_to_transform = :($(Meta.quot(LHS)))
        arguments = :($RHS)
        target_column = QuoteNode(LHS)
        function_definition = Expr(Symbol("->"), arguments, vectorize_function_calls(expr.args[2]))
        assignment_expression = Expr(:call, Symbol("=>"), 
            function_definition,
            target_column
        )
        return Expr(:call, Symbol("=>"), 
            columns_to_transform,
            assignment_expression
            )
    end
    columns_to_transform = Expr(:vect, [QuoteNode(x) for x in RHS]...)
    arguments = Expr(:tuple, RHS...)
    target_column = QuoteNode(LHS)
    function_definition = Expr(Symbol("->"), arguments, vectorize_function_calls(expr.args[2]))
    assignment_expression = Expr(:call, Symbol("=>"), 
            function_definition,
            target_column
        )
    return Expr(:call, Symbol("=>"), 
        columns_to_transform,
        assignment_expression
        )
end

function extract_variable_references(expr::Any, left_of_assignment::Bool=false)
    if is_variable_reference(expr)
        return left_of_assignment ? [(:LHS, expr)] : [(:RHS, expr)]
    elseif expr isa Expr
        if is_function_call(expr)
            return vcat(extract_variable_references.(expr.args[2:end], left_of_assignment)...)
        elseif expr.head == Symbol("=")
            return vcat(extract_variable_references.(expr.args[1:1], true)..., extract_variable_references.(expr.args[2:end], false)...)
        else
            return vcat(extract_variable_references.(expr.args, left_of_assignment)...)
        end
    else
        return []
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

function vectorize_function_calls(expr::Any)
    if expr isa Expr
        if is_function_call(expr)
            vectorized = expr.head == Symbol(".")
            fname = expr.args[1]
            if vectorized || fname in DO_NOT_VECTORIZE
                return Expr(expr.head, fname, vectorize_function_calls.(expr.args[2:end])...)
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
