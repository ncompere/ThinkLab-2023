using Random
using Dates
include("parser.jl")

# we will use several occurences of GRASP to generate individuals of our population
function grasp(n::Int64, m::Int64, nLevel1::Int64, nLevel2::Int64, terminals::Matrix{Float32}, lv1Concentrators::Matrix{Float32}, lv2Concentrators::Matrix{Float32}, C::Int64,
    distanceTerminalConcentrators::Matrix{Int64}, distanceConcentrators::Matrix{Int64}, Lv2Costs::Vector{Int64})

    # sorting terminals by descending distance from each lv1 concentrator
    sortedTerminalsLevel1 = zeros(Int64, n, nLevel1)
    for i in 1:n
        sortedTerminalsLevel1[i,:] = sort(distanceTerminalConcentrators[:,i],rev=true)
    end  
    
    # sorting lv1 concentrators by descending distance from each lv2 concentrator
    sortedLv1Lv2Concentrators = zeros(Int64, nLevel1, nLevel2) 
    for i in 1:nLevel1
        sortedLv1Lv2Concentrators[i,:] = sort(distanceConcentrators[i,:],rev=true)
    end

    # we calculate the sum of the entering arcs for each level 1 concentrators
    potentials = zeros(Int64, nLevel1)
    for i in 1:nLevel1
        potentials[i] = sum(sortedTerminalsLevel1[i,1:numberSelectedLevel1])
    end
    println("potentials: ", potentials)

    # we randomly add the first level 1 concentrator to the solution
    α1 = 0.7
    randomLevel1 = rand(1:nLevel1)
    println("randomLevel1: ", randomLevel1)
    selectedLv1Concentrators::Vector{Int64} = [randomLevel1]
    println("selectedLv1Concentrators: ", selectedLv1Concentrators)
    remainingLv1Concentrators::Vector{Int64} = []
    println("remainingLv1Concentrators: ", remainingLv1Concentrators)
    for i in 1:nLevel1
        append!(remainingLv1Concentrators, i)
    end
    deleteat!(remainingLv1Concentrators, randomLevel1)

    #now, we launch the GRASP until we get this number of level 1 concentrators, for the first objective
    # we add the remaining concentrators with a probability of α1
    
end



m, n, nLevel1, nLevel2, lv1Concentrators, lv2Concentrators, terminals = loadInstance("data/small1.txt")
distanceConcentrators = distancesConcentrators(lv1Concentrators, lv2Concentrators)
distanceTerminalConcentrators = distancesTerminalsConcentrators(lv1Concentrators, terminals)
Lv2Costs = rand(minimum(distanceConcentrators):maximum(distanceConcentrators),nLevel2)
C = floor(Int, 2/3 * nLevel1)
grasp(n, m, nLevel1, nLevel2, terminals, lv1Concentrators, lv2Concentrators, C, distanceTerminalConcentrators, distanceConcentrators, Lv2Costs)
