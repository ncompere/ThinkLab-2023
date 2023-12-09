include("vOptModel.jl")
include("parser.jl")

function main()
println("L'instance suivante est chargée :")
m, n, nLevel1, nLevel2, lv1Concentrators, lv2Concentrators, terminals = loadInstance("data/small3.txt")
println("m = ", m, " (# concentrators)")
println("n = ", n, " (# terminals)")

end