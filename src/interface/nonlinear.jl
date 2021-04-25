@enum NonlinearFunction begin
    SquareRoot
    Square
end

struct NonlinearCombinatorialInstance <: CombinatorialInstance
    combinatorial_structure::Type{<:CombinatorialInstance}
    linear_coefficients::Vector{Float64}
    nonlinear_coefficients::Vector{Float64}
    nonlinear_function::NonlinearFunction
    ε::Float64
end

abstract type NonlinearCombinatorialAlgorithm <: CombinatorialAlgorithm end
