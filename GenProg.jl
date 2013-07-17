function breed(parents::(Expr, Union(Expr, Symbol)))
    main = copy(parents[1])
    other = parents[2]
    parent, splice_ind = rnd_node(main)
    parent_new, ind_new = rnd_node(other)
    parent.args[splice_ind] = parent_new.args[ind_new]
    return main
end

breed(parents::(Symbol, Expr)) = breed((parents[2], parents[1]))
breed(parents::(Symbol, Symbol)) = parents[rand(1:2)]

function rnd_node(ex::Expr)
    current_ind = rand(2:length(ex.args))
    current_node = ex.args[current_ind]
    go_deeper = isa(current_node, Expr) && randbool()
    return go_deeper ? rnd_node(current_node) : (ex, current_ind)
end

rnd_node(s::Symbol) = (expr(:call, {s}), 1)

function st_mutated(ex::Union(Expr, Symbol), F::Array, T::Array, d::Integer)
    return breed((ex, rnd_expr(F, T, d, false)))
end

function rnd_pop(funcs::Array, terms::Array, n::Integer, depth_range::Range1)
    pop = (Union(Expr, Symbol)=>FloatingPoint)[]
    while length(pop) < n
        ex = rnd_expr(funcs, terms, rand(depth_range), randbool())
        pop[ex] = fitness(ex)
    end
    return pop
end

function rnd_expr(funcs::Array, terms::Array, max_d::Int, stunt::Bool)
    F = length(funcs)
    T = length(terms)

    if max_d == 0 || (stunt && rand() < T / (T + F))
        return terms[rand(1:T)]
    else
        func, arity = funcs[rand(1:F)]
        ex = Expr(:call, symbol(string(func)))
        for _ = 1:arity
            push!(ex.args, rnd_expr(funcs, terms, max_d-1, stunt))
        end
        return ex
    end
end

function next_gen(trees::Dict, funcs::Array, terms::Array)
    pop_size = length(trees)
    new_pop = (Union(Expr, Symbol)=>FloatingPoint)[]

    breed_rate = 0.9; surv_rate = 0.09; mut_rate = 0.01;

    for _ = 1:int(breed_rate * pop_size)
        p1 = weighted_choice(trees)
        p2 = weighted_choice(trees)
        child = breed((p1, p2))
        new_pop[child] = fitness(child)
    end

    for _ = 1:int(surv_rate * pop_size)
        survivor = weighted_choice(trees)
        new_pop[survivor] = fitness(survivor)
    end

    for _ = 1:int(mut_rate * pop_size)
        mutant = st_mutated(weighted_choice(trees), funcs, terms, 2)
        new_pop[mutant] = fitness(mutant)
    end

    while length(new_pop) < pop_size
        immigrant = rnd_expr(funcs, terms, rand(2:6), randbool())
        new_pop[immigrant] = fitness(immigrant)
    end

    return new_pop
end

function weighted_choice(choices::Dict{Any, FloatingPoint})
    total = sum([pair[2] for pair in choices])
    r = rand() * total
    upto = 0
    for pair in choices
        weight = pair[2]
        if upto + weight >= r
            return pair[1]
        end
        upto += weight
    end
    # If choices is empty:
    @assert false
end

function fitness(ex::Union(Expr, Symbol))
    f = @eval (x -> $ex)
    return 1 / sum(abs(f(X) - y))
end
