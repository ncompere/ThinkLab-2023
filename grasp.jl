using Random
using Dates
include("parser.jl")
include("functions.jl")

# we will use several occurences of GRASP to generate individuals of our population
function grasp(data::instance)
    
    valueZ1 = 0
    valueZ2 = 0

    # sorting terminals by descending distance from each lv1 concentrator
    sortedTerminalsLevel1 = zeros(Int64, data.n, data.nLevel1)
    println("sortedTerminalsLevel1: ", size(sortedTerminalsLevel1))
    println("c: ", size(data.c))
    for i in 1:data.n
        sortedTerminalsLevel1[i,:] = sort(data.c[:,i],rev=true)
    end 
    
    # sorting lv1 concentrators by descending distance from each lv2 concentrator
    sortedLv1Lv2Concentrators = zeros(Int64, data.nLevel1, data.nLevel2) 
    for i in 1:data.nLevel1
        sortedLv1Lv2Concentrators[i,:] = sort(data.b[i,:],rev=true)
    end

    # we calculate the sum of the entering arcs for each level 1 concentrators
    potentials = zeros(Int64, data.nLevel1)
    for i in 1:data.nLevel1
        potentials[i] = sum(sortedTerminalsLevel1[i,1:data.C])
    end
    
    # we calculate the sum of each level2 concentrator
    potentials2 = zeros(Int64, data.nLevel2)
    for i in 1:data.nLevel2
        for j in 1:data.nLevel1
            potentials2[i] += data.b[j,i]
        end
    end

    # we randomly add the first level 1 concentrator to the solution
    α1 = 0.7
    randomLevel1 = rand(1:data.nLevel1)
    selectedLv1Concentrators::Vector{Int64} = [randomLevel1]
    remainingLv1Concentrators::Vector{Int64} = []
    for i in 1:data.nLevel1
        append!(remainingLv1Concentrators, i)
    end
    deleteat!(remainingLv1Concentrators, randomLevel1)

    #now, we launch the GRASP until we get this number of level 1 concentrators, for the first objective
    # we add the remaining level1 concentrators with a probability of α1
        # we look for the best and worst potentials
    for c1 in 2:data.C
        bestC1 = potentials[remainingLv1Concentrators[1]]
        worstC1 = bestC1

        for i in eachindex(remainingLv1Concentrators)
                currentPotential = potentials[remainingLv1Concentrators[i]]
                if currentPotential < bestC1
                    bestC1 = currentPotential
                end
                if currentPotential > worstC1
                    worstC1 = currentPotential
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

    # now, we select which arcs are selected between terminals and level 1 concentrators
    # the second GRASP starts with a randomly chosen link
    α2 = 0.7
    linksTerminalLevel1 = zeros(Int64,data.n) # we initialize the links
    randTerminal = rand(1:data.n) # we choose a random terminal
    randLevel1 = selectedLv1Concentrators[rand(1:length(selectedLv1Concentrators))] # we choose a random level 1 concentrator
    linksTerminalLevel1[randTerminal] = randLevel1  # we add the link to the solution
    valueZ1 += data.c[randLevel1, randTerminal] # we add the cost of the link to the solution
    valueZ2 += data.c[randLevel1, randTerminal] # we save the distance of the link to use it in the second objective
    remainingTerminals = []
    for i in 1:data.n
        append!(remainingTerminals, i)
    end
    deleteat!(remainingTerminals, randTerminal)

    RCL = Vector{Vector{Int64}}()

    # we add the remaining links with a probability of α2
    for k in 2:data.n
        bestLink1 = data.c[selectedLv1Concentrators[1],remainingTerminals[1]]
        worstLink1 = bestLink1
        for i in eachindex(selectedLv1Concentrators)
            for j in eachindex(remainingTerminals)
                costCandidate = data.c[selectedLv1Concentrators[i],remainingTerminals[j]]
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
        for i in eachindex(selectedLv1Concentrators)
            for j in eachindex(remainingTerminals)
                cost = data.c[selectedLv1Concentrators[i],remainingTerminals[j]]
                if cost <= threshold
                    push!(RCL, [selectedLv1Concentrators[i],remainingTerminals[j]])
                end
            end
        end
    
        newArc = RCL[rand(1:size(RCL,1))]  
        linksTerminalLevel1[newArc[2]] = newArc[1]
        deleteat!(remainingTerminals, findall(x->x==newArc[2],remainingTerminals))

        valueZ1 += data.c[newArc[1], newArc[2]]

        if valueZ2 < data.c[newArc[1], newArc[2]]
            valueZ2 = data.c[newArc[1], newArc[2]]
        end
    end

    # now that we have the set of linked terminals and level 1 concentrators, we determine the set of level 2 concentrators
    α3 = 0.7
    selectedLv2Concentrators = []
    remainingLv2Concentrators = []

    randLevel2 = rand(1:data.nLevel2)
    append!(selectedLv2Concentrators, randLevel2)

    for i in 1:data.nLevel2
        append!(remainingLv2Concentrators, i)
    end
    deleteat!(remainingLv2Concentrators, randLevel2)

    for i in 2:data.nLevel2
        bestC2 = potentials[remainingLv2Concentrators[1]]
        worstC2 = bestC2
        for j in eachindex(remainingLv2Concentrators)
                currentPotential = potentials[remainingLv2Concentrators[j]]
                if currentPotential < bestC2
                    bestC2 = currentPotential
                end
                if currentPotential > worstC2
                    worstC2 = currentPotential
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
    # add the costs of the level 2 concentrators to valueZ1
    for i in eachindex(selectedLv2Concentrators)
        valueZ1 += data.s[i]
    end
    
    # last step: we determine the set of links between level 1 and level 2 concentrators
    α4 = 0.7
    linksLv1Lv2Concentrators = zeros(Int64, size(selectedLv1Concentrators))
    remainingLevel2Links = copy(selectedLv2Concentrators)
    # we select a random link
    randLevel1 = rand(1:length(selectedLv1Concentrators))
    randLevel2 = selectedLv2Concentrators[rand(1:length(selectedLv2Concentrators))]
    linksLv1Lv2Concentrators[randLevel1] = randLevel2
    valueZ1 += data.b[randLevel1, randLevel2]
    
    for i in 1:length(selectedLv1Concentrators)
        if i != randLevel1
            level1 = i
            bestLink2 = data.b[level1, remainingLevel2Links[1]]
            worstLink2 = bestLink2
            for j in eachindex(remainingLevel2Links)
                candidate = data.b[level1, remainingLevel2Links[j]]
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
                candidate = data.b[level1, remainingLevel2Links[j]]
                if candidate <= threshold
                    push!(RCL, j)
                end
            end
            newArc = RCL[rand(1:size(RCL,1))]
            linksLv1Lv2Concentrators[level1] = remainingLevel2Links[newArc]
            valueZ1 += data.b[level1, remainingLevel2Links[newArc]] + data.s[remainingLevel2Links[newArc]]
        end
    end
    #allConcentrators = vcat(selectedLv1Concentrators, selectedLv2Concentrators)

    return solution(selectedLv1Concentrators, linksTerminalLevel1, selectedLv2Concentrators, linksLv1Lv2Concentrators, valueZ1, valueZ2)
end


#=
println("Selected level 1 concentrators: ", solGrasp.selectedLv1)
println("Links between terminals and level 1 concentrators: ", solGrasp.linksTerminalLevel1)
println("Selected level 2 concentrators: ", solGrasp.selectedLv2)
println("Links between level 1 and level 2 concentrators: ", solGrasp.linksLevel1Level2)
println("Value of the first objective: ", solGrasp.valueObj1)
println("Value of the second objective: ", solGrasp.valueObj2)
=#