include("functions.jl")
include("parser.jl")

# GRASP that generates the initial population of feasible solutions
function grasp(data::instance, α::Float64) 

    # initialization of the values of the two objective functions
    valueZ1 = 0
    valueZ2 = 0
    
    # we calculate the sum of the entering arcs for each level 1 concentrators
    sumArcs = zeros(Int64, data.nLevel1)
    for i in 1:data.nLevel1
        for j in 1:data.n
            sumArcs[i] += data.c[i,j]
        end
    end

    # we randomly add the first level 1 concentrator to the solution and then choose the others with a probability of α
    randomLevel1 = rand(1:data.nLevel1)
    selectedLv1Concentrators::Vector{Int64} = [randomLevel1]
    remainingLv1Concentrators::Vector{Int64} = []
    for i in 1:data.nLevel1
        append!(remainingLv1Concentrators, i)
    end
    deleteat!(remainingLv1Concentrators, randomLevel1)
    for c1 in 2:data.C
        bestC1 = sumArcs[remainingLv1Concentrators[1]]
        worstC1 = bestC1
        for i in eachindex(remainingLv1Concentrators)
                concentratorCosts = sumArcs[remainingLv1Concentrators[i]]
                if concentratorCosts < bestC1
                    bestC1 = concentratorCosts
                end
                if concentratorCosts > worstC1
                    worstC1 = concentratorCosts
                end
        end
        threshold = worstC1 - α*(worstC1 - bestC1)
        RCL = []
        for i in eachindex(remainingLv1Concentrators)
            candidate = remainingLv1Concentrators[i]
            if sumArcs[candidate] <= threshold
                append!(RCL, candidate)
            end
        end
        newConcentrator = RCL[rand(1:size(RCL,1))]
        append!(selectedLv1Concentrators, newConcentrator)
        deleteat!(remainingLv1Concentrators, findall(x->x==newConcentrator,remainingLv1Concentrators))
    end

    # we select which arcs are selected between terminals and level 1 concentrators
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
    # we add the remaining links with a probability of α
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
        threshold = worstLink1 - α*(worstLink1 - bestLink1)
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

    # selection of the level 2 concentrators
    # we calculate the sum of entering arcs of each level2 concentrator
    sumArcs2 = zeros(Int64, data.nLevel2)
    for i in 1:data.nLevel2
        for j in 1:data.nLevel1
            sumArcs2[i] += data.b[j,i]
        end
    end
    selectedLv2Concentrators = []
    remainingLv2Concentrators = []
    randLevel2 = rand(1:data.nLevel2)
    append!(selectedLv2Concentrators, randLevel2)
    for i in 1:data.nLevel2
        append!(remainingLv2Concentrators, i)
    end
    deleteat!(remainingLv2Concentrators, randLevel2)
    for i in 2:data.nLevel2
        bestC2 = sumArcs2[remainingLv2Concentrators[1]]
        worstC2 = bestC2
        for j in eachindex(remainingLv2Concentrators)
                concentratorCosts = sumArcs2[remainingLv2Concentrators[j]]
                if concentratorCosts < bestC2
                    bestC2 = concentratorCosts
                end
                if concentratorCosts > worstC2
                    worstC2 = concentratorCosts
                end
        end
        threshold = worstC2 - α*(worstC2 - bestC2)
        RCL = []
        for j in eachindex(remainingLv2Concentrators)
            candidate = sumArcs2[remainingLv2Concentrators[j]]
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
    # we add the costs of opening the level 2 concentrators to Z1
    for i in selectedLv2Concentrators
        valueZ1 += data.s[i]
    end
    # last step: we determine the set of links between level 1 and level 2 concentrators
    linksLv1Lv2Concentrators = zeros(Int64, size(selectedLv1Concentrators))
    remainingLevel2Links = copy(selectedLv2Concentrators)  
    # we select a random link
    randLevel1 = rand(1:length(selectedLv1Concentrators))
    randLevel2 = rand(1:length(selectedLv2Concentrators))
    linksLv1Lv2Concentrators[randLevel1] = selectedLv2Concentrators[randLevel2]
    chosenLv2::Vector{Int64} = []
    push!(chosenLv2, selectedLv2Concentrators[randLevel2])
    valueZ1 += data.b[selectedLv1Concentrators[randLevel1], selectedLv2Concentrators[randLevel2]]   
    for i in 1:length(selectedLv1Concentrators)
        if i != randLevel1
            level1 = i
            bestLink2 = data.b[selectedLv1Concentrators[level1], remainingLevel2Links[1]]
            worstLink2 = bestLink2
            for j in eachindex(remainingLevel2Links)
                candidate = data.b[selectedLv1Concentrators[level1], remainingLevel2Links[j]]
                if candidate < bestLink2
                    bestLink2 = candidate
                end
                if candidate > worstLink2
                    worstLink2 = candidate
                end
            end
            threshold = worstLink2 - α*(worstLink2 - bestLink2)
            RCL = []
            for j in eachindex(remainingLevel2Links)
                candidate = data.b[selectedLv1Concentrators[level1], remainingLevel2Links[j]]
                if candidate <= threshold
                    push!(RCL, j)
                end
            end
            # we select a random link from the restricted candidate list
            newArc = RCL[rand(1:size(RCL,1))]
            linksLv1Lv2Concentrators[level1] = remainingLevel2Links[newArc]
            push!(chosenLv2, remainingLevel2Links[newArc])
            valueZ1 += data.b[selectedLv1Concentrators[level1], remainingLevel2Links[newArc]]
        end
    end
    # if a selected level 2 concentrator is not linked to a level 1 concentrator, we delete it
    while length(selectedLv2Concentrators) > length(chosenLv2)
        if selectedLv2Concentrators[i] ∉ chosenLv2
            valueZ1 -= data.s[selectedLv2Concentrators[i]]
            deleteat!(selectedLv2Concentrators, i)
        end
    end
    return solution(selectedLv1Concentrators, linksTerminalLevel1, selectedLv2Concentrators, linksLv1Lv2Concentrators, valueZ1, valueZ2)
end


#data = loadInstance("data/small1.txt")
#solGrasp = grasp(data)

#=
println("Selected level 1 concentrators: ", solGrasp.selectedLv1)
println("Links between terminals and level 1 concentrators: ", solGrasp.linksTerminalLevel1)
println("Selected level 2 concentrators: ", solGrasp.selectedLv2)
println("Links between level 1 and level 2 concentrators: ", solGrasp.linksLevel1Level2)
println("Value of the first objective: ", solGrasp.valueObj1)
println("Value of the second objective: ", solGrasp.valueObj2)
=#