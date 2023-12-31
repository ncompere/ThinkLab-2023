include("functions.jl")

function path_relinking(sol1::solution, sol2::solution, data::instance, nbIter::Int64 = 20)
    # Initializing the new solution
    # data.c = transpose(data.c)
    new_sol = deepcopy(sol1)
    set_of_solutions = []
    # LV1
    # create two vectors of the differences between the level 1 concentrators of the two solutions
    diff1::Vector{Int64} = setdiff(sol1.selectedLv1, sol2.selectedLv1)
    diff2::Vector{Int64} = setdiff(sol2.selectedLv1, sol1.selectedLv1)
    iter::Int64 = 1
    while iter <= nbIter && !isempty(diff1) && !isempty(diff2)
        # we choose a random lv1 to add from sol2
        lv1_to_add::Int64 = popat!(diff2, rand(1:length(diff2)))
        lv1_to_del::Int64 = popat!(diff1, rand(1:length(diff1)))
        # we delete the lv1_to_del from the new solution
        filter!(x -> x != lv1_to_del, new_sol.selectedLv1)
        # we add the lv1_to_add to the new solution
        push!(new_sol.selectedLv1, lv1_to_add)
        terminals_to_move = findall(x -> x == lv1_to_del, new_sol.linksTerminalLevel1)
        for terminal in terminals_to_move
            new_sol.linksTerminalLevel1[terminal] = lv1_to_add
        end
        new_sol.valueObj1 = obj1(new_sol, data)
        new_sol.valueObj2 = obj2(new_sol, data.c)
        if new_sol.valueObj1 < sol1.valueObj1 || new_sol.valueObj2 < sol1.valueObj2
            push!(set_of_solutions, new_sol)
            diff1 = setdiff(new_sol.selectedLv1, sol2.selectedLv1)
            diff2 = setdiff(sol2.selectedLv1, new_sol.selectedLv1)
        else
            new_sol = deepcopy(sol1)
        end
        iter += 1
    end

    # LV2
    new_sol = deepcopy(sol1)
    # create two vectors of the differences between the level 2 concentrators of the two solutions
    diff1 = setdiff(sol1.selectedLv2, sol2.selectedLv2)
    diff2 = setdiff(sol2.selectedLv2, sol1.selectedLv2)
    nbIter = length(diff2)
    iter = 1
    while iter <= nbIter && !isempty(diff1) && !isempty(diff2)
        # we choose a random lv2 to add from sol2
        lv2_to_add = popat!(diff2, rand(1:length(diff2)))
        lv2_to_del = popat!(diff1, rand(1:length(diff1)))
        # we delete the lv2_to_del from the new solution
        filter!(x -> x != lv2_to_del, new_sol.selectedLv2)
        # we add the lv2_to_add to the new solution
        push!(new_sol.selectedLv2, lv2_to_add)
        for j in eachindex(new_sol.linksLevel1Level2)
            if new_sol.linksLevel1Level2[j] == lv2_to_del
                new_sol.linksLevel1Level2[j] = lv2_to_add
            end
        end
        new_sol.valueObj1 = obj1(new_sol, data)
        new_sol.valueObj2 = obj2(new_sol, data.c)
        if new_sol.valueObj1 < sol1.valueObj1 || new_sol.valueObj2 < sol1.valueObj2
            push!(set_of_solutions, new_sol)
            diff1 = setdiff(new_sol.selectedLv2, sol2.selectedLv2)
            diff2 = setdiff(sol2.selectedLv2, new_sol.selectedLv2)
        else
            new_sol = deepcopy(sol1)
        end
        iter += 1
    end

    return set_of_solutions
end
