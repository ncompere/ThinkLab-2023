include("vOptModel.jl")
include("parser.jl")
include("plot.jl")
include("grasp.jl")
include("functions.jl")


function main()
    # chargement de l'instance
    println("Veuillez introduire de nom de l'instance dans le dossier data (ex: small1) :")
    instance = readline()
    data = loadInstance("data/$instance.txt")

    # trouver des solutions initiales avec 20 itérations de GRASP
    Z1::Vector{Int64} = []
    Z2::Vector{Int64} = []
    for i in 1:100
        solGrasp = grasp(data)
        push!(Z1, solGrasp.valueObj1)
        push!(Z2, solGrasp.valueObj2)
    end

    # plot des solutions de GRASP
    plot(Z1,Z2,seriestype=:scatter, title="Initial solutions", xlabel="Z1", ylabel="Z2")

end

main()