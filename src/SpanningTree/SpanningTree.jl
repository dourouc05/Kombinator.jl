module UniformMatroid

using Kombinator
using JuMP

import Kombinator: solve, dimension, value, values

export SpanningTreeInstance, SpanningTreeSolution, MinBudgetedUniformMatroidSolution, BudgetedSpanningTreeSolution, SimpleBudgetedSpanningTreeSolution, BudgetedSpanningTreeLagrangianSolution

include("st.jl")
include("st_prim.jl")
include("st_budgeted_lagrangian.jl")

end
