include("vOptModel.jl")
include("parser.jl")
include("plot.jl")
include("grasp.jl")
include("functions.jl")
include("skipList.jl")
include("tabu.jl")

using Plots

function main()
    # chargement de l'instance
    println("Veuillez introduire de nom de l'instance dans le dossier data (ex: small1) :")
    instance = readline()
    data = loadInstance("data/$instance.txt")
    #plot_instance(data)

    # generattion d'une population initiale de solutions avec GRASP
    nbIterationsGRASP = 200
    solutionsInitiales::Vector{solution} = []
    #archive = SkipList()

    # initialisation des vecteurs pour le plot des solutions
    # plot grasp
    Z1::Vector{Int64} = []
    Z2::Vector{Int64} = []
    # plot taboo
    T1::Vector{Int64} = []
    T2::Vector{Int64} = []
    getTime = time()
    for i in 1:nbIterationsGRASP
        solGrasp = grasp(data)
        push!(solutionsInitiales, solGrasp)
        push!(Z1, solGrasp.valueObj1)
        push!(Z2, solGrasp.valueObj2)
        solTabu = tabu(solGrasp, data)
        push!(T1, solTabu.valueObj1)
        push!(T2, solTabu.valueObj2)
        #addArchive(archive, [solGrasp.valueObj1, -solGrasp.valueObj2])
    end
    timeGRASP = round(time()- getTime, digits=4)
    println("Temps de résolution : $timeGRASP s")
    #affichageSkiplist(archive)
    #println("Nombre de points non dominés : ", nbrPoint(archive))
    #points = setOfSolutions(archive)

    # solve avec MOA
    Y1, Y2 = solve_vOpt(vOptRes(data))
#=
    for i in eachindex(points)
        # add to Z1 the first index of each point in the set of solutions
        push!(Z1, points[i][1])
        # add to Z2 the second index of each point in the set of solutions
        push!(Z2, -(points[i][2]))
    end
=#
    plot(Y1,Y2,seriestype=:scatter, title="vOPT", xlabel="Y1", ylabel="Y2")
    plot!(Z1,Z2,seriestype=:scatter, title="solutions GRASP", xlabel="Z1", ylabel="Z2")
    plot!(T1,T2,seriestype=:scatter, title="solutions Tabu", xlabel="T1", ylabel="T2")
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