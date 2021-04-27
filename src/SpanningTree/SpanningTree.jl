module SpanningTree

using Kombinator

using DataStructures
using JuMP
using LightGraphs

import Base: copy
import Kombinator: solve, dimension, approximation_ratio, approximation_term

export SpanningTreeInstance, SpanningTreeSolution, BudgetedSpanningTreeSolution, SimpleBudgetedSpanningTreeSolution, BudgetedSpanningTreeLagrangianSolution

include("st.jl")

include("helpers.jl")
include("helpers_lp.jl")

include("st_prim.jl")
include("st_dp.jl")
include("st_lp.jl")

include("st_budgeted_lagrangian.jl")
include("st_budgeted_lagrangian_refined.jl")
include("st_budgeted_lagrangian_refined_iterated.jl")
include("st_budgeted_dp.jl")
include("st_budgeted_lp.jl")

end
