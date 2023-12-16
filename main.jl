#include("vOptModel.jl")
include("parser.jl")
#include("plot.jl")
include("grasp.jl")
include("functions.jl")
include("skipList.jl")

using Plots

function main()
    # chargement de l'instance
    println("Veuillez introduire de nom de l'instance dans le dossier data (ex: small1) :")
    instance = readline()
    data = loadInstance("data/$instance.txt")

    # generate a population of initial solutions with GRASP
    nbIterationsGRASP = 200
    solutionsInitiales::Vector{solution} = []
    archive = SkipList()

    # initialisation des vecteurs pour le plot des solutions
    Z1::Vector{Int64} = []
    Z2::Vector{Int64} = []

    for i in 1:nbIterationsGRASP
        solGrasp = grasp(data)
        push!(solutionsInitiales, solGrasp)
        addArchive(archive, [solGrasp.valueObj1, -(solGrasp.valueObj2)])
    end
    #affichageSkiplist(archive)
    println("nombre de points : ", nbrPoint(archive))
    pts = setOfSolutions(archive)

    for i in eachindex(pts)
        # add to Z1 the first index of each point in the set of solutions
        push!(Z1, pts[i][1])
        # add to Z2 the second index of each point in the set of solutions
        push!(Z2, -pts[i][2])
    end




    # plot des solutions de GRASP
    plot(Z1,Z2,seriestype=:scatter, title="Initial solutions", xlabel="Z1", ylabel="Z2")

end

main()