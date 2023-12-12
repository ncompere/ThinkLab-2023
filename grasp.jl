using Random
using Dates
include("parser.jl")

function grasp(terminals::Matrix{Float32}, lv1Concentrators::Matrix{Float32}, lv2Concentrators::Matrix{Float32}, C::Int64,
    distanceTerminalConcentrators::Matrix{Int64}, distanceConcentrators::Matrix{Int64}, Lv2Costs::Vector{Int64})

    # sorting terminals by descending distance from each lv1 concentrator
    sortedTerminalsLevel1::Matrix{Int64} = Matrix{Int64}(undef,(length(terminals),length(lv1Concentrators)))
    for j in 1:length(lv1Concentrators)
        sortedTerminalsLevel1[:,i] = sort(terminals,by= term -> distanceTerminalConcentrators[term,j],rev=true)
    end
    
    return sortedTerminalsLevel1
end

m, n, nLevel1, nLevel2, lv1Concentrators, lv2Concentrators, terminals = loadInstance("data/small1.txt")
distanceConcentrators = distancesConcentrators(lv1Concentrators, lv2Concentrators)
distanceTerminalConcentrators = distancesTerminalsConcentrators(lv1Concentrators, terminals)
Lv2Costs = rand(minimum(distanceConcentrators):maximum(distanceConcentrators),nLevel2)
C = floor(Int, 2/3 * nLevel1)
sorted = grasp(terminals, lv1Concentrators, lv2Concentrators, C, distanceTerminalConcentrators, distanceConcentrators, Lv2Costs)