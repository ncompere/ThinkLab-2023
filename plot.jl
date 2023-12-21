using Plots

# include("vOptModel.jl")
include("parser.jl")
include("functions.jl")
include("tabu.jl")

function plot_instance_init(data::instance)
    plot(legend=:outerbottom, size=(800,800)) # to start with an empty plot
    plot!(scatter!(data.lv1Concentrators[:,1], data.lv1Concentrators[:,2], label="level 1 concentrators", markershape=:diamond, color="blue"))
    plot!(scatter!(data.lv2Concentrators[:,1], data.lv2Concentrators[:,2], label="level 2 concentrators", markershape=:rect, color="red"))
    plot!(scatter!(data.terminals[:,1], data.terminals[:,2], label="terminals", color="black"))
    display(plot!(title="Initial map"))
    savefig("plot/initial_map.png")
end

function plot_solver(sol::solution, data::instance)
    
end

function plot_solution(sol::solution, data::instance, title="Solution")
    plot(legend=:outerbottom, size=(800,800)) # to start with an empty plot
    plot!(scatter!(data.lv1Concentrators[sol.selectedLv1,1], data.lv1Concentrators[sol.selectedLv1,2], label="level 1 concentrators", markershape=:diamond, color="blue"))
    plot!(scatter!(data.lv2Concentrators[sol.selectedLv2,1], data.lv2Concentrators[sol.selectedLv2,2], label="level 2 concentrators", markershape=:rect, color="red"))
    plot!(scatter!(data.terminals[:,1], data.terminals[:,2], label="terminals", color="black"))
    # ploting links between terminals and concentrators at level 1
    # for i in 1:data.n
    #     plot!(plot([data.terminals[i,1], data.lv1Concentrators[sol.linksTerminalLevel1[i]]], [data.terminals[i,2], data.lv1Concentrators[sol.linksTerminalLevel1[i]]], linewidth=2, color="black"))
    # end
    # plot!([data.terminals[1:data.n,1], data.lv1Concentrators[sol.linksTerminalLevel1[1:data.n],1]], [data.terminals[1:data.n,2], data.lv1Concentrators[sol.linksTerminalLevel1[1:data.n],2]], linewidth=2, color="black")
    for i in 1:data.n
        plot!([data.terminals[i,1], data.lv1Concentrators[sol.linksTerminalLevel1[i],1]], [data.terminals[i,2], data.lv1Concentrators[sol.linksTerminalLevel1[i],2]], linewidth=1, color="grey", primary=false)
    end
    for i in 1:length(sol.selectedLv1)
        plot!([data.lv1Concentrators[sol.selectedLv1[i],1], data.lv2Concentrators[sol.linksLevel1Level2[i],1]], [data.lv1Concentrators[sol.selectedLv1[i],2], data.lv2Concentrators[sol.linksLevel1Level2[i],2]], linewidth=1, color="grey", primary=false)
    end
    display(plot!(title=title))
    savefig("plot/$title.png")
end

# testing
# data = loadInstance("data/small1.txt")
# println("Instance loaded")
# sol = grasp(data)
# println("GRASP done")
# # # println("LV1 coordinates : ", data.lv1Concentrators)
# # # println("LV2 coordinates : ", data.lv2Concentrators)
# # # println("Terminals coordinates : ", data.terminals)
# # # println("Solution : ", sol)
# display(plot_instance_init(data))
# plot_solution(sol, data, "GRASP solution")
# sol = tabu(sol, data)
# println("Tabu done")
# plot_solution(sol, data, "Tabu solution")