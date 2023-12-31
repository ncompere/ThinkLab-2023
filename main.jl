include("vOptModel.jl")
include("parser.jl")
include("plot.jl")
include("grasp.jl")
include("functions.jl")
include("skipList.jl")
include("tabu.jl")
include("path_relinking.jl")

using Statistics

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
    for i in 1:nbIterationsGRASP/2
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
    for i in (nbIterationsGRASP/2)+1:nbIterationsGRASP
        solGrasp = grasp(data, α)
        push!(solutionsInitiales, solGrasp)
        push!(Z1, solGrasp.valueObj1)
        push!(Z2, solGrasp.valueObj2)
        solTabu = tabu_obj2(solGrasp, data)
        push!(solutionsTabu, solTabu)
        push!(T1, solTabu.valueObj1)
        push!(T2, solTabu.valueObj2)
        addArchive(archiveGRASP, [solGrasp.valueObj1, -solGrasp.valueObj2])
        addArchive(archiveTabu, [solTabu.valueObj1, -solTabu.valueObj2])
    end
    timeMeta = round(time()- getTime, digits=4)
    println("Temps de résolution : $timeMeta s")

    pointsGRASP = setOfSolutions(archiveGRASP)
    pointsTabu = setOfSolutions(archiveTabu)

    # -------------------------------------------------------------------------------------------------------------
    # Path Relinking
    # we add the best 10 solutions for each objective in two refSets
    lengthRefSet::Int64 = 10
    refSet1::Vector{solution} = createRefSetZ1(solutionsTabu[1:floor(Int,length(solutionsTabu)/2)], lengthRefSet) 
    refSet2::Vector{solution} = createRefSetZ2(solutionsTabu[floor(Int,length(solutionsTabu)/2)+1:end], lengthRefSet)
    
    # println("RefSet 1 : ", refSet1)
    # println("RefSet 2 : ", refSet2)

    solutionsPR = []
    archivePR = SkipList()
    P1::Vector{Int64} = []
    P2::Vector{Int64} = []
    # we avoid the solutions that were already in the same pair
    pairesInterdites::Vector{solution} = []

    # we stop when a new solution is added to the refSet
    stopCriterion::Bool = false

    # path_relinking(refSet1[1], refSet2[1], data)

    pairs = vec(collect(Iterators.product(1:lengthRefSet, 1:lengthRefSet)))
    for pair in pairs
        solPR = path_relinking(refSet1[pair[1]], refSet2[pair[2]], data)
        for s in solPR
            s = tabu(s, data)
            push!(solutionsPR, s)
            push!(P1, s.valueObj1)
            push!(P2, s.valueObj2)
            addArchive(archivePR, [s.valueObj1, -s.valueObj2])
        end
    end
    pointsPR = setOfSolutions(archivePR)

    # -------------------------------------------------------------------------------------------------------------
    # solve avec MOA
    Y1, Y2 = solve_vOpt(vOptRes(data))

    # -------------------------------------------------------------------------------------------------------------
    # write results in a file
    open("file/$instance.txt", "w") do f
        write(f, "Solution recap \n")
        write(f, "\n")
        write(f, "vOpt \n")
        write(f, "Mean obj1 : $(mean(Y1)) \n")
        write(f, "Mean obj2 : $(mean(Y2)) \n")
        write(f, "Min obj1 : $(minimum(Y1)) \n")
        write(f, "Min obj2 : $(minimum(Y2)) \n")
        write(f, "Max obj1 : $(maximum(Y1)) \n")
        write(f, "Max obj2 : $(maximum(Y2)) \n")
        write(f, "\n")
        write(f, "GRASP \n")
        mean_grasp_obj1 = mean(Z1)
        mean_grasp_obj2 = mean(Z2)
        write(f, "Mean obj1 : $mean_grasp_obj1 \n")
        write(f, "Mean obj2 : $mean_grasp_obj2 \n")
        write(f, "Min obj1 : $(minimum(Z1)) \n")
        write(f, "Min obj2 : $(minimum(Z2)) \n")
        write(f, "Max obj1 : $(maximum(Z1)) \n")
        write(f, "Max obj2 : $(maximum(Z2)) \n")
        write(f, "\n")
        write(f, "Tabu \n")
        mean_tabu_obj1 = mean(T1)
        mean_tabu_obj2 = mean(T2)
        write(f, "Mean obj1 : $mean_tabu_obj1 \n")
        write(f, "Mean obj2 : $mean_tabu_obj2 \n")
        write(f, "Min obj1 : $(minimum(T1)) \n")
        write(f, "Min obj2 : $(minimum(T2)) \n")
        write(f, "Max obj1 : $(maximum(T1)) \n")
        write(f, "Max obj2 : $(maximum(T2)) \n")
        write(f, "\n")
        write(f, "Path relinking \n")
        write(f, "Mean obj1 : $(mean(P1)) \n")
        write(f, "Mean obj2 : $(mean(P2)) \n")
        write(f, "Min obj1 : $(minimum(P1)) \n")
        write(f, "Min obj2 : $(minimum(P2)) \n")
        write(f, "Max obj1 : $(maximum(P1)) \n")
        write(f, "Max obj2 : $(maximum(P2)) \n")
    end

    # -------------------------------------------------------------------------------------------------------------
    # plot solution space
    # plot(Y1,Y2,seriestype=:scatter, title="Objective space", xlabel="Z1", ylabel="Z2", label="vOpt", size=(800,600))
    # plot!(Z1,Z2,seriestype=:scatter, label="GRASP")
    # display(plot!(T1,T2,seriestype=:scatter, label="Tabu"))
    # savefig("plot/$instance Solution space.png")

    plot(Y1,Y2,seriestype=:scatter, title="$instance Objective space", xlabel="Z1", ylabel="Z2", label="vOpt", size=(800,600))
    plot!(Z1,Z2,seriestype=:scatter, label="GRASP")
    plot!(T1,T2,seriestype=:scatter, label="Tabu")
    display(plot!(P1,P2,seriestype=:scatter, label="Path relinking"))
    savefig("plot/$instance Solution space.png")
    
    # -------------------------------------------------------------------------------------------------------------
    # solution plot on a map
    plot_instance_init(data, instance)
    plot_solution(solutionsInitiales[1], data, instance, "GRASP solution")
    plot_solution(solutionsTabu[1], data, instance, "Tabu solution")
    if !isempty(solutionsPR)
        plot_solution(solutionsPR[1], data, instance, "Path relinking solution")
    end

    # -------------------------------------------------------------------------------------------------------------
    # Plot non dominated points

    arc_Z1::Vector{Int64} = []
    arc_Z2::Vector{Int64} = []
    # plot taboo
    arc_T1::Vector{Int64} = []
    arc_T2::Vector{Int64} = []
    # plot path relinking
    arc_P1::Vector{Int64} = []
    arc_P2::Vector{Int64} = []

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

    for i in eachindex(pointsPR)
        # add to P1 the first index of each point in the set of solutions
        push!(arc_P1, pointsPR[i][1])
        # add to P2 the second index of each point in the set of solutions
        push!(arc_P2, -(pointsPR[i][2]))
    end

    plot(Y1,Y2,seriestype=:scatter, title="$instance Non dominated points", xlabel="Z1", ylabel="Z2", label="vOpt", size=(800,600))
    plot!(arc_Z1,arc_Z2,seriestype=:scatter, label="GRASP")
    plot!(arc_T1,arc_T2,seriestype=:scatter, label="Tabu")
    display(plot!(arc_P1,arc_P2,seriestype=:scatter, label="Path relinking"))
    savefig("plot/$instance Y_N.png")

end

main()