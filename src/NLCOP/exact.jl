struct ExactNonlinearSolver <: NonlinearCombinatorialAlgorithm
    solver # MINLP solver with support for the nonlinear function.
end

function solve(nli::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver)
    return solve(nli, algo, Val(nli.nonlinear_function))
end

function solve(nli::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver, ::Val{SquareRoot})
    # This formulation is valid only for maximising (concave objective 
    # function). Otherwise, think about general MINLP solvers...
    @assert nli.combinatorial_structure.objective == Maximise()

    # Base formulation for the combinatorial problem.
    m, x = formulation(nli.combinatorial_structure, nli.formulation, solver=algo.solver)

    # Formulation for the nonlinear term. 
    dot_product = @variable(m, lower_bound=0.0) # b^T x
    nonlinear_term = @variable(m, lower_bound=0.0) # t

    set_name(dot_product, "dot_product")
    set_name(nonlinear_term, "nonlinear_term")

    @constraint(m, eq, dot_product == sum(nli.nonlinear_coefficients[i] * x[i] for i in eachindex(nli.nonlinear_coefficients)))
    @constraint(m, cone, [1 + dot_product, 1 - dot_product, 2 * nonlinear_term] in SecondOrderCone())

    # New objective.
    @objective(m, Max, sum(nli.linear_coefficients[i] * x[i] for i in eachindex(nli.nonlinear_coefficients)) + nonlinear_term)

    # Solve the new formulation.
    set_silent(m)
    t0 = time_ns()
    optimize!(m)
    t1 = time_ns()

    if termination_status(m) != MOI.OPTIMAL
        error("The model was not solved correctly.")
    end

    # Retrieve the solution.
    dict_sol = Dict(k => JuMP.value(x[k]) for k in eachindex(nli.linear_coefficients))
    return make_solution(nli.combinatorial_structure, dict_sol)
end

function solve(nli::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver, ::Val{Square})
    # This formulation is valid only for minimising (convex objective 
    # function). Otherwise, think about general MINLP solvers...
    @assert nli.combinatorial_structure.objective == Minimise()

    # Base formulation for the combinatorial problem.
    m, x = formulation(nli.combinatorial_structure, solver=algo.solver)

    # Formulation for the nonlinear term. Quite easy, JuMP supports quadratic 
    # objective functions.
    dot_product = @variable(m, lower_bound=0.0) # b^T x
    @constraint(m, eq, dot_product == sum(nli.nonlinear_coefficients[i] * x[i] for i in eachindex(nli.nonlinear_coefficients)))

    # New objective.
    @objective(m, Max, sum(nli.linear_coefficients[i] * x[i] for i in eachindex(nli.nonlinear_coefficients)) + nonlinear_term^2)

    # Solve the new formulation.
    set_silent(m)
    t0 = time_ns()
    optimize!(m)
    t1 = time_ns()

    if termination_status(m) != MOI.OPTIMAL
        error("The model was not solved correctly.")
    end

    # Retrieve the solution.
    dict_sol = Dict(k => JuMP.value(x[k]) for k in eachindex(nli.linear_coefficients))
    return make_solution(nli.combinatorial_structure, dict_sol)
end
