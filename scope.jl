import ScopedValues

const MyValue = ScopedValues.ScopedValue{Int}()

function step1()
    return MyValue[] + 1
end

function step2()
    return MyValue[] * 2
end

function step3()
    return MyValue[] - 3
end

function process_steps(steps)
    if isempty(steps)
        return MyValue[]
    else
        current_step = first(steps)
        remaining_steps = steps[2:end]
        new_value = current_step()
        println("After $(current_step): ", new_value)
        
        ScopedValues.@with MyValue => new_value begin
            process_steps(remaining_steps)
        end
    end
end

function process_chain(initial_value, steps)
    ScopedValues.@with MyValue => initial_value begin
        println("Initial: ", MyValue[])
        process_steps(steps)
    end
end

steps = [step1, step2, step3]
result = process_chain(0, steps)
println("Final result: ", result)