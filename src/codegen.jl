# use multiple dispatch to generate code 
rewrite(command::Command) = rewrite(Val(command.command), command)

function rewrite(::Val{:generate}, command::Command)
    dfname = command.df
    target_column = get_LHS(command.arguments[1])
    bitmask = build_bitmask(command)
    # check that target_column does not exist in dfname
    df2 = gensym()
    sdf = gensym()
    RHS = replace_variable_references(sdf, command.arguments[1].args[2]) |> vectorize_function_calls
    quote
        if !($target_column in names($dfname))
            local $df2 = copy($dfname)
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
    target_column = get_LHS(command.arguments[1])
    bitmask = build_bitmask(command)
    # check that target_column does not exist in dfname
    df2 = gensym()
    sdf = gensym()
    RHS = replace_variable_references(sdf, command.arguments[1].args[2]) |> vectorize_function_calls
    quote
        if $target_column in names($dfname)
            local $df2 = copy($dfname)
            local $sdf = view($df2, $bitmask, :)
            if typeof($RHS[1,1]) != typeof($sdf[1, $target_column])
                $df2[!, $target_column] = convert(Vector{typeof($RHS[1,1])}, $df2[!, $target_column])
            end
            $sdf[!, $target_column] .= $RHS
            $df2
        else
            ArgumentError("Column \"$($target_column)\" does not exist in $(names($dfname))") |> throw
        end
    end |> esc
end

function get_LHS(expr::Expr)
    expr.head == :(=) || error("Expected assignment expression")
    vars = extract_variable_references(expr)
    String([y[2] for y in vars if y[1] == :LHS][1])
end

function build_assignment_formula(expr::Expr)
    expr.head == :(=) || error("Expected assignment expression")
    vars = extract_variable_references(expr)
    LHS = [y[2] for y in vars if y[1] == :LHS][1]
    RHS = [y[2] for y in vars if y[1] == :RHS]
    if length(RHS) == 0
        # if no variable is used in RHS of assignment, create an anonymous variable
        columns_to_transform = :(AsTable([]))
        arguments = :_
    else
        columns_to_transform = Expr(:vect, [QuoteNode(x) for x in RHS]...)
        arguments = Expr(:tuple, RHS...)
    end
    target_column = QuoteNode(LHS)
    function_definition = quote
        $arguments -> $(vectorize_function_calls(expr.args[2]))
    end
    return quote
        $columns_to_transform => ($function_definition) => $target_column
    end
end

function build_bitmask(df::Any, condition::Any)
    replace_variable_references(df, condition) |> vectorize_function_calls
end

build_bitmask(command::Command) = isnothing(command.condition) ? :(BitVector(fill(1, nrow($(command.df))))) : build_bitmask(command.df, command.condition)

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
