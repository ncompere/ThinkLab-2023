using JuMP
using HiGHS
using GLPK
using MultiObjectiveAlgorithms

include("data/didactic.jl")

# Define the model
#model = JuMP.Model(() -> MOA.Optimizer(HiGHS.Optimizer))
#set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())


# Create a JuMP model
model = Model(GLPK.Optimizer)

# Define decision variables
@variable(model, x[i in I, j in J], Bin)
@variable(model, y[j in J, k in K], Bin)
@variable(model, z[k in K], Bin)

# Define the objective function
@objective(model, Min,
    sum(c[i, j] * x[i, j] for i in I, j in J) +
    sum(b[j, k] * y[j, k] for j in J, k in K) +
    sum(s[k] * z[k] for k in K)
)

# Constraints
@constraint(model, [i in I], sum(x[i, j] for j in J) == 1)  # (2)
@constraint(model, [i in I, j in J], x[i, j] <= sum(y[j, k] for k in K))  # (3)
@constraint(model, [j in J, k in K], sum(y[j, k] for j in J) <= z[k])  # (4)
@constraint(model, [j in J], sum(y[j, k] for k in K) <= 1)  # (5)

# Solve the problem
optimize!(model)

# Display results
println("Objective Value: ", objective_value(model))
println("Assignment:")
for i in I
    for j in J
        if value(x[i, j]) > 0.5
            println("Assign terminal $i to concentrator $j on the first level")
        end
    end
end

println("\nConnection:")
for j in J
    for k in K
        if value(y[j, k]) > 0.5
            println("Connect concentrator $j on the first level to concentrator $k on the second level")
        end
    end
end

println("\nInstallation:")
for k in K
    if value(z[k]) > 0.5
        println("Install concentrator at site $k on the second level")
    end
end
