using Random
using Dates
include("parser.jl")

# we will use several occurences of GRASP to generate individuals of our population
function grasp(n::Int64, m::Int64, nLevel1::Int64, nLevel2::Int64, terminals::Matrix{Float32}, lv1Concentrators::Matrix{Float32}, lv2Concentrators::Matrix{Float32}, C::Int64,
    distanceTerminalConcentrators::Matrix{Int64}, distanceConcentrators::Matrix{Int64}, Lv2Costs::Vector{Int64})
    
    valueZ1 = 0
    vaueZ2 = 0

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
        potentials[i] = sum(sortedTerminalsLevel1[i,1:C])
    end
    
    # we calculate the sum of each level2 concentrator
    potentials2 = zeros(Int64, nLevel2)
    for i in 1:nLevel2
        for j in 1:nLevel1
            potentials2[i] += distanceConcentrators[j,i]
        end
    end

    println("C: $C")
    # we randomly add the first level 1 concentrator to the solution
    α1 = 0.7
    randomLevel1 = rand(1:nLevel1)
    println("randomLevel1: ", randomLevel1)
    selectedLv1Concentrators::Vector{Int64} = [randomLevel1]
    remainingLv1Concentrators::Vector{Int64} = []
    for i in 1:nLevel1
        append!(remainingLv1Concentrators, i)
    end
    deleteat!(remainingLv1Concentrators, randomLevel1)
    println("selectedLv1Concentrators: ", selectedLv1Concentrators)
    println("remainingLv1Concentrators: ", remainingLv1Concentrators)

    #now, we launch the GRASP until we get this number of level 1 concentrators, for the first objective
    # we add the remaining level1 concentrators with a probability of α1
        # we look for the best and worst potentials
    for c1 in 2:C
        bestC1 = potentials[remainingLv1Concentrators[1]]
        println("bestC1: ", bestC1)
        worstC1 = bestC1
        for i in eachindex(remainingLv1Concentrators)
            if i > 1
                currentPotential = potentials[remainingLv1Concentrators[i]]
                if currentPotential < bestC1
                    bestC1 = currentPotential
                end
                if currentPotential > worstC1
                    worstC1 = currentPotential
                end
            end
        end
        threshold = worstC1 - α1*(worstC1 - bestC1)

        RCL = []
        for i in eachindex(remainingLv1Concentrators)
            candidate = remainingLv1Concentrators[i]
            if potentials[candidate] <= threshold
                append!(RCL, candidate)
            end
        end
        newConcentrator = RCL[rand(1:size(RCL,1))]
        append!(selectedLv1Concentrators, newConcentrator)
        deleteat!(remainingLv1Concentrators, findall(x->x==newConcentrator,remainingLv1Concentrators))
    end
    println("selectedLv1Concentrators: ", selectedLv1Concentrators)
    # now, we select which arcs are selected between terminals and level 1 concentrators
    # the second GRASP starts with a randomly chosen link
    α2 = 0.7
    linksTerminalLevel1 = zeros(Int64,n) # we initialize the links
    randTerminal = rand(1:n) # we choose a random terminal
    randLevel1 = selectedLv1Concentrators[rand(1:C)] # we choose a random level 1 concentrator
    linksTerminalLevel1[randTerminal] = randLevel1  # we add the link to the solution
    valueZ1 += distanceTerminalConcentrators[randLevel1, randTerminal] # we add the cost of the link to the solution

    remainingTerminals = []
    for i in 1:n
        append!(remainingTerminals, i)
    end
    deleteat!(remainingTerminals, randTerminal)

    RCL = Vector{Vector{Int64}}()

    # we add the remaining links with a probability of α2
    for k in 2:n
        bestLink1 = distanceTerminalConcentrators[remainingLv1Concentrators[1],remainingTerminals[1]]
        worstLink1 = bestLink1
        for i in eachindex(remainingLv1Concentrators)
            for j in eachindex(remainingTerminals)
                costCandidate = distanceTerminalConcentrators[remainingLv1Concentrators[i],remainingTerminals[j]]
                if costCandidate < bestLink1
                    bestLink1 = costCandidate
                end
                if costCandidate > worstLink1
                    worstLink1 = costCandidate
                end
            end
        end

        threshold = worstLink1 - α2*(worstLink1 - bestLink1)
        empty!(RCL)

        for i in eachindex(remainingLv1Concentrators)
            for j in eachindex(remainingTerminals)
                cost = distanceTerminalConcentrators[remainingLv1Concentrators[i],remainingTerminals[j]]
                if cost <= threshold
                    push!(RCL, [remainingLv1Concentrators[i],remainingTerminals[j]])
                end
            end
        end

        newLink = RCL[rand(1:size(RCL,1))]  
        #selectedConcentratorLv1 = [newLink[1]]
        linksTerminalLevel1[newLink[2]] = newLink[1]
        deleteat!(remainingTerminals, findall(x->x==newLink[2],remainingTerminals))
        valueZ1 += distanceTerminalConcentrators[newLink[1], newLink[2]]

    end

    # now that we have the set of linked terminals and level 1 concentrators, we determine the set of level 2 concentrators
    α3 = 0.7
    selectedLv2Concentrators = []
    remainingLv2Concentrators = []
    for i in 1:nLevel2
        append!(remainingLv2Concentrators, i)
    end

    for i in 1:nLevel2
        bestC2 = potentials[remainingLv2Concentrators[1]]
        worstC2 = bestC2
        for j in eachindex(remainingLv2Concentrators)
            if j > 1
                currentPotential = potentials[remainingLv2Concentrators[j]]
                if currentPotential < bestC2
                    bestC2 = currentPotential
                end
                if currentPotential > worstC2
                    worstC2 = currentPotential
                end
            end
        end
        threshold = worstC2 - α3*(worstC2 - bestC2)
        RCL = []
        for j in eachindex(remainingLv2Concentrators)
            candidate = potentials[remainingLv2Concentrators[j]]
            if candidate <= threshold
                push!(RCL, j)
            end
        end
        newLv2Concentrator = RCL[rand(1:size(RCL,1))]
        if newLv2Concentrator ∉ selectedLv2Concentrators
            push!(selectedLv2Concentrators, newLv2Concentrator)
        end
        deleteat!(remainingLv2Concentrators, findall(x->x==newLv2Concentrator,remainingLv2Concentrators))
    end
    println("selectedLv2Concentrators: ", selectedLv2Concentrators)
    println("remainingLv2Concentrators: ", remainingLv2Concentrators)
    # add the costs of the level 2 concentrators to valueZ1
    for i in eachindex(selectedLv2Concentrators)
        valueZ1 += Lv2Costs[i]
    end
    
    # last step: we determine the set of links between level 1 and level 2 concentrators
    α4 = 0.7
    linksLv1Lv2Concentrators = zeros(Int64, C)
    remainingLevel2Links = copy(selectedLv2Concentrators)
    # we select a random link
    randLevel1 = rand(1:C)
    randLevel2 = selectedLv2Concentrators[rand(1:length(selectedLv2Concentrators))]
    linksLv1Lv2Concentrators[randLevel1] = randLevel2
    valueZ1 += distanceConcentrators[randLevel1, randLevel2]
    
    for i in 1:length(selectedLv1Concentrators)
        if i != randLevel1
            level1 = i
            bestLink2 = distanceConcentrators[level1, remainingLevel2Links[1]]
            worstLink2 = bestLink2
            for j in eachindex(remainingLevel2Links)
                candidate = distanceConcentrators[level1, remainingLevel2Links[j]]
                if candidate < bestLink2
                    bestLink2 = candidate
                end
                if candidate > worstLink2
                    worstLink2 = candidate
                end
            end
            threshold = worstLink2 - α4*(worstLink2 - bestLink2)
            RCL = []
            for j in eachindex(remainingLevel2Links)
                candidate = distanceConcentrators[level1, remainingLevel2Links[j]]
                if candidate <= threshold
                    push!(RCL, j)
                end
            end
            newLink = RCL[rand(1:size(RCL,1))]
            linksLv1Lv2Concentrators[level1] = remainingLevel2Links[newLink]
            println("linksLv1Lv2Concentrators: ", linksLv1Lv2Concentrators)
            valueZ1 += distanceConcentrators[level1, remainingLevel2Links[newLink]]
        end
    end
    println("selectedLevel1Concentrators: ", selectedLv1Concentrators)
    allConcentrators = vcat(selectedLv1Concentrators, selectedLv2Concentrators)
    println("all working Concentrators: ", allConcentrators)
    println("links Lv 1Lv2 Concentrators: ", linksLv1Lv2Concentrators)
end



m, n, nLevel1, nLevel2, lv1Concentrators, lv2Concentrators, terminals = loadInstance("data/small1.txt")
distanceConcentrators = distancesConcentrators(lv1Concentrators, lv2Concentrators)
distanceTerminalConcentrators = distancesTerminalsConcentrators(lv1Concentrators, terminals)
Lv2Costs = rand(minimum(distanceConcentrators):maximum(distanceConcentrators),nLevel2)
C = floor(Int, 2/3 * nLevel1)
grasp(n, m, nLevel1, nLevel2, terminals, lv1Concentrators, lv2Concentrators, C, distanceTerminalConcentrators, distanceConcentrators, Lv2Costs)
