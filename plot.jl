using Plots

# include("vOptModel.jl")
include("parser.jl")
include("functions.jl")

function plot_instance_init(data::instance)
    plot(legend=:outerbottom) # to start with an empty plot
    plot!(scatter!(data.lv1Concentrators[:,1], data.lv1Concentrators[:,2], label="level 1 concentrators", markershape=:diamond, color="blue"))
    plot!(scatter!(data.lv2Concentrators[:,1], data.lv2Concentrators[:,2], label="level 2 concentrators", markershape=:rect, color="red"))
    plot!(scatter!(data.terminals[:,1], data.terminals[:,2], label="terminals", color="black"))
end

# testing
data = loadInstance("data/small1.txt")
plot_instance_init(data)