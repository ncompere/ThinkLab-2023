using JuMP
using Gurobi
using HiGHS
import MultiObjectiveAlgorithms as MOA

include("parser.jl")
include("functions.jl")

function vOptRes(filename::String)

    data::instance = loadInstance(filename)
    # transpose c
    data.c = transpose(data.c)

    # display information about the instance to solve
    println("(users)    : $(data.n)")
    println("(services) : $(data.m)")

    TSUFLPmodel = JuMP.Model(() -> MOA.Optimizer(HiGHS.Optimizer))
    set_optimizer_attribute(TSUFLPmodel, MOA.Algorithm(), MOA.EpsilonConstraint())

    # set_attribute(TSUFLPmodel, MOA.SolutionLimit(), 4)

    set_silent(TSUFLPmodel)

    # decision variables
    @variable(TSUFLPmodel, x[1:data.n,1:data.nLevel1], Bin)
    @variable(TSUFLPmodel, y[1:data.nLevel1,1:data.nLevel2], Bin)
    @variable(TSUFLPmodel, z[1:data.nLevel2], Bin)
    @variable(TSUFLPmodel, Z >=0)

    # @expression(TSUFLPmodel, z1, sum(c[i,j]*x[i,j] for i in 1:n, j in 1:nLevel1) + sum(b[j,k]*y[j,k] for j in 1:nLevel1, k in 1:nLevel2) + sum(s[k]*z[k] for k in 1:nLevel2))
    # objective function to minimize the maximum distance between terminals and their nearest first level concentrator
    # @expression(TSUFLPmodel, z2, maximum(minimum(c[i,j]*x[i,j]) for i in 1:n, j in 1:nLevel1))
    # @expression(TSUFLPmodel, Z)

    @objective(TSUFLPmodel, Min, [sum(data.c[i,j]*x[i,j] for i in 1:data.n, j in 1:data.nLevel1) + sum(data.b[j,k]*y[j,k] for j in 1:data.nLevel1, k in 1:data.nLevel2) + sum(data.s[k]*z[k] for k in 1:data.nLevel2),Z])
    # @objective(TSUFLPmodel, Min, [z1,Z])
    # @objective(TSUFLPmodel, Min, sum(c[i,j]*x[i,j] for i in 1:n, j in 1:nLevel1) + sum(b[j,k]*y[j,k] for j in 1:nLevel1, k in 1:nLevel2) + sum(s[k]*z[k] for k in 1:nLevel2))


    @constraint(TSUFLPmodel, cst1[i=1:data.n] ,sum(x[i,j] for j in 1:data.nLevel1) == 1)
    @constraint(TSUFLPmodel, cst2[i=1:data.n, j=1:data.nLevel1] ,x[i,j] <= sum(y[j,k] for k in 1:data.nLevel2))
    @constraint(TSUFLPmodel, cst3[j=1:data.nLevel1, k=1:data.nLevel2], y[j,k] <= z[k])
    @constraint(TSUFLPmodel, cst4[j=1:data.nLevel1], sum(y[j,k] for k in 1:data.nLevel2) <= 1)

    # capacity constraint
    @constraint(TSUFLPmodel, cst5[j = 1:data.nLevel1] ,sum(x[i,j] for i in 1:data.n) <= data.C)

    # linearization of obj2 (min-max)
    @constraint(TSUFLPmodel, cst6[i = 1:data.n, j=1:data.nLevel1], Z >= x[i,j]*data.c[i,j])

    return TSUFLPmodel
end
    
function solve_vOpt(TSUFLPmodel::Model)
    # solve the TSUFLPmodel
    optimize!(TSUFLPmodel)
    solution_summary(TSUFLPmodel)

    # collecting solutions in the decision space
    println(has_values(TSUFLPmodel) ? "has values" : "no values")
    println(result_count(TSUFLPmodel))

    for i in 1:result_count(TSUFLPmodel)
        println("Solution $i")
        println("Objective value: ", objective_value(TSUFLPmodel, result=i))
        println("x = ", value.(TSUFLPmodel[:x], result=i))
        println("y = ", value.(TSUFLPmodel[:y], result=i))
        println("z = ", value.(TSUFLPmodel[:z], result=i))
        println("Z = ", value.(TSUFLPmodel[:Z], result=i))
    end
end

# testing
solve_vOpt(vOptRes("data/small1.txt"))