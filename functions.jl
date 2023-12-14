# Not used yet
mutable struct instance
    m::Int64
    n::Int64
    nLevel1::Int64
    nLevel2::Int64
    lv1Concentrators::Array{Float32,2}
    lv2Concentrators::Array{Float32,2}
    terminals::Array{Float32,2}
    C::Int64
    c::Array{Int64,2}
    b::Array{Int64,2}
    s::Vector{Int64}
end

mutable struct solution
    selectedLv1::Vector{Int64}
    linksTerminalLevel1::Vector{Int64}
    selectedLv2::Vector{Int64}
    linksLevel1Level2::Vector{Int64}
    valueObj1::Int64
    valueObj2::Int64
end

# function to check if a solution is feasible
function isFeasible(sol::solution, C::Int64)
    # check if the number of concentrators at level 1 is less than the capacity
    if length(sol.selectedLv1) > C
        return false
    end
    # check if each terminal is connected to a concentrator at level 1
    for i in 1:length(sol.linksTerminalLevel1)
        if sol.linksTerminalLevel1[i] == 0
            return false
        end
    end
    # check if each concentrator at level 1 is connected to a concentrator at level 2
    for i in 1:length(sol.selectedLv1)
        if sol.linksLevel1Level2[i] == 0
            return false
        end
    end
    return true
end

#=
# function to calculate the value of the objective function 1
function obj1(sol::solution, distanceTerminalConcentrators::Array{Int64,2}, distanceConcentrators::Array{Int64,2}, Lv2Costs::Vector{Int64})
    # calculate the costs of the links between the terminals and the selected concentrators at level 1
    costLinksTerminalConcentrators = 0
    for i in 1:length(sol.linksTerminalLevel1)
        costLinksTerminalConcentrators += distanceTerminalConcentrators[i,sol.linksTerminalLevel1[i]]
    end

    # calculate the costs of the links between the concentrators at level 1 and the concentrators at level 2
    costLinksLevel1Level2 = 0
    for i in 1:length(sol.linksLevel1Level2)
        costLinksLevel1Level2 += distanceTerminalConcentrators[sol.selectedLv1[i],sol.linksLevel1Level2[i]]
    end

    # calculate the cost of opening the concentrators at level 2
    costLevel2 = 0
    for i in sol.selectedLv2
        costLevel2 += Lv2Costs[i]
    end

    #calculate the total cost
    totalCost = costLinksTerminalConcentrators + costLinksLevel1Level2 + costLevel2

    return totalCost
end


# function to calculate the value of the objective function 2
function obj2(sol::solution, d::Array{Int64,2})
    # calculate the maximum distance between the terminals and the selected concentrators at level 1 that we seek to minimize
    maxDistanceTerminalConcentrators = 0
    for i in 1:length(sol.linksTerminalLevel1)
        if d[i,sol.linksTerminalLevel1[i]] > maxDistanceTerminalConcentrators
            maxDistanceTerminalConcentrators = d[i,sol.linksTerminalLevel1[i]]
        end
    end   
    return maxDistanceTerminalConcentrators
end

=#
