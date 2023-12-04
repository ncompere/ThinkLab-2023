using JuMP, Gurobi, HiGHS

import MathOptInterface as MOI
import MultiObjectiveAlgorithms as MOA

# Define the model
model = Model(HiGHS.Optimizer)
MOI.set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())