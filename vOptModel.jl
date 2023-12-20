using JuMP
using Gurobi
using HiGHS
import MultiObjectiveAlgorithms as MOA
using Plots

include("parser.jl")
include("functions.jl")

function vOptRes(data::instance)

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


    @objective(TSUFLPmodel, Min, [sum(data.c[i,j]*x[i,j] for i in 1:data.n, j in 1:data.nLevel1) + sum(data.b[j,k]*y[j,k] for j in 1:data.nLevel1, k in 1:data.nLevel2) + sum(data.s[k]*z[k] for k in 1:data.nLevel2),Z])

    @constraint(TSUFLPmodel, cst1[i=1:data.n] ,sum(x[i,j] for j in 1:data.nLevel1) == 1)
    @constraint(TSUFLPmodel, cst2[i=1:data.n, j=1:data.nLevel1] ,x[i,j] <= sum(y[j,k] for k in 1:data.nLevel2))
    @constraint(TSUFLPmodel, cst3[j=1:data.nLevel1, k=1:data.nLevel2], y[j,k] <= z[k])
    @constraint(TSUFLPmodel, cst4[j=1:data.nLevel1], sum(y[j,k] for k in 1:data.nLevel2) <= 1)

    # the maximum number of concentrators at level 1 is C
    @constraint(TSUFLPmodel, cst5, sum(y[j,k] for j in 1:data.nLevel1, k in 1:data.nLevel2) <= data.C)

    # linearization of obj2 (min-max)
    @constraint(TSUFLPmodel, cst6[i = 1:data.n, j=1:data.nLevel1], Z >= x[i,j]*data.c[i,j])

    return TSUFLPmodel
end
    
function solve_vOpt(TSUFLPmodel::Model)
    getTime = time()
    # solve the TSUFLPmodel
    optimize!(TSUFLPmodel)
    timevOPt = round(time()- getTime, digits=4)
    println("Resolution time : $timevOPt s")
    solution_summary(TSUFLPmodel)

    # collecting solutions in the decision space
    println(has_values(TSUFLPmodel) ? "has values" : "no values")
    println(result_count(TSUFLPmodel))

    # plot
    Z1::Vector{Float32} = []
    Z2::Vector{Float32} = []
    for i in 1:result_count(TSUFLPmodel)
        println("Solution $i")
        println("Objective value: ", objective_value(TSUFLPmodel, result=i))
        #println("x = ", value.(TSUFLPmodel[:x], result=i))
        #println("y = ", value.(TSUFLPmodel[:y], result=i))
        #println("z = ", value.(TSUFLPmodel[:z], result=i))
        #println("Z = ", value.(TSUFLPmodel[:Z], result=i))
        
        push!(Z1, objective_value(TSUFLPmodel, result=i)[1])
        push!(Z2, objective_value(TSUFLPmodel, result=i)[2])
    end

    # plot the values of Z1,Z2
    #plot!(Z1,Z2,seriestype=:scatter, title="Pareto front", xlabel="Z1", ylabel="Z2")
    return Z1,Z2
end

# testing
#data = loadInstance("data/small1.txt")
#solve_vOpt(vOptRes(data))