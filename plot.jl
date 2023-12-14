using Plots

# include("vOptModel.jl")
include("parser.jl")
include("functions.jl")

function plot_instance(fname::String)
    m, n, nLevel1, nLevel2, lv1Concentrators, lv2Concentrators, terminals = loadInstance(fname)

    plot(legend=:outerbottom) # to start with an empty plot
    plot!(scatter!(lv1Concentrators[:,1], lv1Concentrators[:,2], label="level 1 concentrators", markershape=:diamond, color="blue"))
    plot!(scatter!(lv2Concentrators[:,1], lv2Concentrators[:,2], label="level 2 concentrators", markershape=:rect, color="red"))
    plot!(scatter!(terminals[:,1], terminals[:,2], label="terminals", color="black"))

end

# testing
plot_instance("data/small1.txt")