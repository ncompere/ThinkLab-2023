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
    # TODO : change type of selected to Set{Int64}
    # TODO : change type of links to Dict{Int64,Int64}
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


# function to calculate the value of the objective function 1
function obj1(sol::solution, data::instance)
    cost::Int64 = 0
    # calculate the costs of the links between the terminals and the selected concentrators at level 1
    for i in eachindex(sol.linksTerminalLevel1)
        cost += data.c[sol.linksTerminalLevel1[i],i]
    end

    # calculate the costs of opening the selected concentrators at level 2
    for i in sol.selectedLv2
        cost += data.s[i]
    end

    # calculate the costs of the links between the selected concentrators at level 1 and the selected concentrators at level 2
    for i in eachindex(sol.selectedLv1)
        cost += data.b[sol.selectedLv1[i],sol.linksLevel1Level2[i]]
    end
    return cost
end


# function to calculate the value of the objective function 2
function obj2(sol::solution, c::Array{Int64,2})
    # calculate the maximum distance between the terminals and the selected concentrators at level 1 that we seek to minimize
    maxDistanceTerminalConcentrators::Int64 = 0
    for i in 1:length(sol.linksTerminalLevel1)
        if c[sol.linksTerminalLevel1[i],i] > maxDistanceTerminalConcentrators
            maxDistanceTerminalConcentrators = c[sol.linksTerminalLevel1[i],i]
        end
    end   
    return maxDistanceTerminalConcentrators
end

#= Function to calculate a vector of the closest lv1 concentrators for each terminal
Terminals are the indexes, elemnts are the closest concentrators
Considered concentraters are only from the selected ones
=#
function closest_concentrators(sol::solution, data::instance)
    closest_concentrators::Vector{Int64} = []
    for i in 1:data.n
        push!(closest_concentrators, argmax(data.c[:,i])[1])
    end
    for i in 1:data.n
        # println("Terminal : ", i)
        for j in sol.selectedLv1
            # println("Comparison : ", data.c[j,i] < data.c[closest_concentrators[i],i])
            closest_concentrators[i] = data.c[j,i] < data.c[closest_concentrators[i],i] ? j : closest_concentrators[i]
        end
    end
    return closest_concentrators
end

function closest_lv2_concentrators(sol::solution, data::instance)
    closest = Dict{Int64,Int64}()
    for i in sol.selectedLv1
        closest[i] = argmax(data.b[i,:])
    end                                     

    for i in sol.selectedLv1
        for j in sol.selectedLv2
            # println("Checking $i, $j : ", data.b[i,j])
            # println("Stored $i, $closest[i] : ", data.b[i,closest[i]])
            closest[i] = data.b[i,j] < data.b[i,closest[i]] ? j : closest[i]
            # println("Closest : ", closest[i])
        end
    end
    return closest
end

# function to create a refset for the first objective
function createRefSetZ1(solutions::Vector{solution}, lengthRefSet::Int64)
    # initialization of the reference sets
    refSet::Vector{solution} = []
    for i in 1:lengthRefSet
        bestZ = typemax(Int64)
        indexBestZ = -1
        for j in eachindex(solutions)
            candidate = solutions[j].valueObj1
            if candidate < bestZ
                bestZ = solutions[j].valueObj1
                bestSolZ1 = candidate
                indexBestZ = j
            end
        end
        push!(refSet, solutions[indexBestZ])
        deleteat!(solutions, indexBestZ)
    end
    # the most distant solutions to the refSet1 are added to build the second half
    for i in Int(lengthRefSet/2)+1:lengthRefSet
        maxDist = 0
        indexMaxDist = -1
        for j in 1:length(solutions)
            for k in eachindex(refSet)
                distCandidate = distanceSolutions(solutions[j], refSet[k])
                if distCandidate > maxDist
                    maxDist = distCandidate
                    indexMaxDist = j
                end
            end
        end
        push!(refSet, solutions[indexMaxDist])
        deleteat!(solutions, indexMaxDist)
    end
    return refSet
end

# function to create a refset for the second objective
function createRefSetZ2(solutions::Vector{solution}, lengthRefSet::Int64)
    # initialization of the reference sets
    refSet::Vector{solution} = []
    for i in 1:Int(lengthRefSet/2)
        bestZ = typemax(Int64)
        indexBestZ = -1
        for j in eachindex(solutions)
            candidate = solutions[j].valueObj2
            if candidate < bestZ
                bestZ = solutions[j].valueObj2
                bestSolZ1 = candidate
                indexBestZ = j
            end
        end
        push!(refSet, solutions[indexBestZ])
        deleteat!(solutions, indexBestZ)
    end
    # the most distant solutions to the refSet1 are added to build the second half
    for i in Int(lengthRefSet/2)+1:lengthRefSet
        maxDist = 0
        indexMaxDist = -1
        for j in 1:length(solutions)
            for k in eachindex(refSet)
                distCandidate = distanceSolutions(solutions[j], refSet[k])
                if distCandidate > maxDist
                    maxDist = distCandidate
                    indexMaxDist = j
                end
            end
        end
        push!(refSet, solutions[indexMaxDist])
        deleteat!(solutions, indexMaxDist)
    end

    return refSet
end

# function to calculate the distance between two points
function distanceSolutions(S1::solution,S2::solution)::Int64
    return length(setdiff(S1.selectedLv1,S2.selectedLv1)) + length(setdiff(S2.selectedLv1,S1.selectedLv1)) +
           length(setdiff(S1.selectedLv2,S2.selectedLv2)) + length(setdiff(S2.selectedLv2,S1.selectedLv2))
end