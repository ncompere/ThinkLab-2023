using JuMP
using Gurobi
import MultiObjectiveAlgorithms as MOA

include("parser.jl")

function vOptRes(filename::String)
    nameinstance = String(split(Vector(split(filename, '/'))[end],'.')[1])               

    m, n, nLevel1, nLevel2, lv1Concentrators, lv2Concentrators, terminals = loadInstance("data/small1.txt")

    # display information about the instance to solve
    println("(users)    : $n")
    println("(services) : $m")

    # generation of the distance and cost matrixes c b, s
    c = distancesTerminalsConcentrators(terminals, lv1Concentrators)
    b = distancesConcentrators(lv1Concentrators, lv2Concentrators)

    # cost of opening concentrators at level 2
    s = [rand([i for i in minimum(b):maximum(b)]) for k in eachindex(lv2Concentrators)]

    # max number of concentrators at level 1
    C = 7

    TSUFLPmodel = JuMP.Model(() -> MOA.Optimizer(Gurobi.Optimizer))
    set_optimizer_attribute(TSUFLPmodel, MOA.Algorithm(), MOA.EpsilonConstraint())

    #set_silent(TSUFLPmodel)
    #set_attribute(TSUFLPmodel, MOA.Algorithm(), MOA.EpsilonConstraint())
    #set_attribute(TSUFLPmodel, MOA.SolutionLimit(), 4)

    @variable(TSUFLPmodel,x[1:n,1:nLevel1], Bin)
    @variable(TSUFLPmodel,y[1:nLevel1,1:nLevel2], Bin)
    @variable(TSUFLPmodel,z[1:nLevel2], Bin)
    @variable(TSUFLPmodel, Z >=0)

    #@expression(TSUFLPmodel, z1, sum(c[i,j]*x[i,j] for i in 1:n, j in 1:nLevel1) + sum(b[j,k]*y[j,k] for j in 1:nLevel1, k in 1:nLevel2) + sum(s[k]*z[k] for k in 1:nLevel2))
    #@expression(TSUFLPmodel, z2, Z)
    #@objective(TSUFLPmodel, Min, [z1,z2])

    @objective(TSUFLPmodel, Min, [sum(c[i,j]*x[i,j] for i in 1:n, j in 1:nLevel1) + sum(b[j,k]*y[j,k] for j in 1:nLevel1, k in 1:nLevel2) + sum(s[k]*z[k] for k in 1:nLevel2),Z])

    
    @constraint(TSUFLPmodel, [i = 1:n] ,sum(x[i,j] for j in 1:nLevel1) == 1)
    @constraint(TSUFLPmodel, [i=1:n, j=1:nLevel1] ,x[i,j] <= sum(y[j,k] for k in 1:nLevel2))
    @constraint(TSUFLPmodel, [j=1:nLevel1, k=1:nLevel2], y[j,k] <= z[k])
    @constraint(TSUFLPmodel, [j = 1:nLevel1] ,sum(y[j,k] for k in 1:nLevel2) <= 1)

    # capacity constraint
    @constraint(TSUFLPmodel, [j = 1:nLevel1] ,sum(x[i,j] for i in 1:n) <= C)

    # linearization of obj2 (min-max)
    @constraint(TSUFLPmodel, [i = 1:n, j=1:nLevel1] ,Z >= x[i,j]*c[i,j])

    set_optimizer(TSUFLPmodel, () -> MOA.Optimizer(Gurobi.Optimizer))
    #set_attribute(TSUFLPmodel, MOA.Algorithm(), MOA.EpsilonConstraint())
    
    # solve the TSUFLPmodel
    optimize!(TSUFLPmodel)
    solution_summary(TSUFLPmodel)


end

vOptRes("data/small1.txt")