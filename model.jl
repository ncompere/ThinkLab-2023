using JuMP
import HiGHS
import MultiObjectiveAlgorithms as MOA

# Define the model
model = JuMP.Model(() -> MOA.Optimizer(HiGHS.Optimizer))
set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())

