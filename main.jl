include("vOptModel.jl")
include("parser.jl")
include("plot.jl")
include("grasp.jl")
include("functions.jl")
include("skipList.jl")
include("tabu.jl")

# using Plots

function main()
    # chargement de l'instance
    println("Veuillez introduire de nom de l'instance dans le dossier data (ex: small1) :")
    instance = readline()
    data = loadInstance("data/$instance.txt")
    #plot_instance(data)

    # generattion d'une population initiale de solutions avec GRASP
    nbIterationsGRASP = 200
    α = 0.7
    solutionsInitiales::Vector{solution} = []
    solutionsTabu::Vector{solution} = []
    archiveGRASP = SkipList()
    archiveTabu = SkipList()

    # initialisation des vecteurs pour le plot des solutions
    # plot grasp
    Z1::Vector{Int64} = []
    Z2::Vector{Int64} = []
    # plot taboo
    T1::Vector{Int64} = []
    T2::Vector{Int64} = []
    getTime = time()
    for i in 1:nbIterationsGRASP
        solGrasp = grasp(data, α)
        push!(solutionsInitiales, solGrasp)
        push!(Z1, solGrasp.valueObj1)
        push!(Z2, solGrasp.valueObj2)

        solTabu = tabu(solGrasp, data)
        push!(solutionsTabu, solTabu)
        push!(T1, solTabu.valueObj1)
        push!(T2, solTabu.valueObj2)
        addArchive(archiveGRASP, [solGrasp.valueObj1, -solGrasp.valueObj2])
        addArchive(archiveTabu, [solTabu.valueObj1, -solTabu.valueObj2])
    end
    timeGRASP = round(time()- getTime, digits=4)
    println("Temps de résolution : $timeGRASP s")

    pointsGRASP = setOfSolutions(archiveGRASP)
    pointsTabu = setOfSolutions(archiveTabu)

    # solve avec MOA
    Y1, Y2 = solve_vOpt(vOptRes(data))
    # plot solution space
    plot(Y1,Y2,seriestype=:scatter, title="Objective space", xlabel="Z1", ylabel="Z2", label="vOpt", size=(800,600))
    plot!(Z1,Z2,seriestype=:scatter, label="GRASP")
    display(plot!(T1,T2,seriestype=:scatter, label="Tabu"))
    savefig("plot/Solution space.png")

    # solution plot on a map
    plot_instance_init(data)
    plot_solution(solutionsInitiales[1], data, "GRASP solution")
    plot_solution(solutionsTabu[1], data, "Tabu solution")

    arc_Z1::Vector{Int64} = []
    arc_Z2::Vector{Int64} = []
    # plot taboo
    arc_T1::Vector{Int64} = []
    arc_T2::Vector{Int64} = []

    for i in eachindex(pointsGRASP)
        # add to Z1 the first index of each point in the set of solutions
        push!(arc_Z1, pointsGRASP[i][1])
        # add to Z2 the second index of each point in the set of solutions
        push!(arc_Z2, -(pointsGRASP[i][2]))
    end

    for i in eachindex(pointsTabu)
        # add to T1 the first index of each point in the set of solutions
        push!(arc_T1, pointsTabu[i][1])
        # add to T2 the second index of each point in the set of solutions
        push!(arc_T2, -(pointsTabu[i][2]))
    end

    plot(Y1,Y2,seriestype=:scatter, title="Non dominated points", xlabel="Z1", ylabel="Z2", label="vOpt", size=(800,600))
    plot!(arc_Z1,arc_Z2,seriestype=:scatter, label="GRASP")
    display(plot!(arc_T1,arc_T2,seriestype=:scatter, label="Tabu"))
    savefig("plot/Y_N.png")
#=

    # initialization of the reference sets
    refSet1::Vector{solution} = []
    refSet2::Vector{solution} = []
    lengthRefSet = 10

    # we add the best 5 solutions of each objective to each refset
    for i in 1:lengthRefSet
        bestZ1 = typemax(Int64)
        indexBestZ1 = -1
        for j in eachindex(solutionsInitiales)
            candidate = solutionsInitiales[j].valueObj1
            if candidate < bestZ1
                bestZ1 = solutionsInitiales[j].valueObj1
                bestSolZ1 = candidate
                indexBestZ1 = j
            end
        end
        push!(refSet1, solutionsInitiales[indexBestZ1])
        deleteat!(solutionsInitiales, indexBestZ1)
    end

    for i in 1:lengthRefSet
        bestZ2 = typemax(Int64)
        indexBestZ2 = -1
        for j in eachindex(solutionsInitiales)
            candidate = solutionsInitiales[j].valueObj2
            if candidate < bestZ2
                bestZ2 = candidate
                bestSolZ2 = solutionsInitiales[j]
                indexBestZ2 = j
            end
        end
        push!(refSet2, solutionsInitiales[indexBestZ2])
        deleteat!(solutionsInitiales, indexBestZ2)
    end
    =#
end

main()