include("grasp.jl")
include("functions.jl")
include("parser.jl")

# ------------------------------------------------------------------------
# Tabu search for the first objective
# ------------------------------------------------------------------------

function tabu(sol::solution, data::instance)

    # Parameters
    nbIter::Int64 = 10
    tabu_list::Vector{Tuple{Int64,Int64}} = []
    tabu_list_size::Int64 = 7
    iter::Int64 = 1
    no_more_candidates::Bool = false

    # Initialization
    current_solution::solution = deepcopy(sol)
    best_solution::solution = deepcopy(sol)

    # Tabu search
    while iter <= nbIter && !no_more_candidates
        best_move, possible_moves = choose_candidates(current_solution, data) # List of candidate moves
        if best_move[1] == 0
            no_more_candidates = true
        else
            # check if the move is in tabu list
            while best_move[2] ∈ tabu_list
                best_move, possible_moves = choose_other_candidate(current_solution, data, possible_moves)
            end
            if best_move[1] == 0
                no_more_candidates = true
            else
                # update the current solution
                # concentrator_to_delete = findall(x -> x == best_move[2][1], current_solution.selectedLv1)
                filter!(x -> x != best_move[2][1], current_solution.selectedLv1)
                push!(current_solution.selectedLv1, best_move[2][2])
                terminals_to_move = findall(x -> x == best_move[2][1], current_solution.linksTerminalLevel1)
                for terminal in terminals_to_move
                    current_solution.linksTerminalLevel1[terminal] = closest_concentrators(current_solution,data)[terminal]
                end
                # for concentrator in concentrator_to_delete
                #     deleteat!(current_solution.linksLevel1Level2, concentrator)
                #     push!(current_solution.linksLevel1Level2, closest_lv2_concentrators(current_solution,data)[best_move[2][2]])
                # end
                current_solution.valueObj1 = obj1(current_solution, data)
                current_solution.valueObj2 = obj2(current_solution, data.c)
                # update the tabu list
                if length(tabu_list) >= tabu_list_size
                    popfirst!(tabu_list)
                end
                push!(tabu_list, best_move[2])
                # update the best solution
                if best_solution.valueObj1 > current_solution.valueObj1
                    best_solution = deepcopy(current_solution)
                end
            end
        end
        iter+=1
    end
    return best_solution
end

# Generates the current solution feasable neighbors
function choose_candidates(sol::solution, data::instance)
    candidate_list = (0, (0,0))
    # Get all the not selected concentrators
    not_selected_lv1_concentrators = setdiff(1:size(data.lv1Concentrators)[1], sol.selectedLv1)
    possible_moves = vec(collect(Iterators.product(sol.selectedLv1, not_selected_lv1_concentrators)))
    improved_found::Bool = false
    while !isempty(possible_moves) && !improved_found
        move = pop!(possible_moves)
        temp_solution = deepcopy(sol)
        # Deleting the concentrator from the selected list
        # concentrator_to_delete = findall(x -> x == move[1], temp_solution.selectedLv1)
        filter!(x -> x != move[1], temp_solution.selectedLv1)
        # Adding the concentrator to the selected list
        push!(temp_solution.selectedLv1, move[2])
        # Updating the links from terminals to concentrators
        terminals_to_move = findall(x -> x == move[1], temp_solution.linksTerminalLevel1)
        for terminal in terminals_to_move
            temp_solution.linksTerminalLevel1[terminal] = closest_concentrators(temp_solution,data)[terminal]
        end
        # Updating the links from concentrators to concentrators
        # for i in concentrator_to_delete
        #     deleteat!(temp_solution.linksLevel1Level2, i)
        #     push!(temp_solution.linksLevel1Level2, closest_lv2_concentrators(temp_solution,data)[move[2]])
        # end
        # Check if the solution is feasible
        if isFeasible(temp_solution, data.C)
            # Check if the solution is better than the current solution
            if sol.valueObj1 > obj1(temp_solution, data)
                candidate_list = (obj1(temp_solution, data), move)
                improved_found = true
            end
        end
    end
    return candidate_list, possible_moves
end

function choose_other_candidate(sol::solution, data::instance, possible_moves::Vector{Tuple{Int64,Int64}})
    candidate_list = (0, (0,0))
    improved_found::Bool = false
    while !isempty(possible_moves) && !improved_found
        move = pop!(possible_moves)
        temp_solution = deepcopy(sol)
        # Deleting the concentrator from the selected list
        # concentrator_to_delete = findall(x -> x == move[1], temp_solution.selectedLv1)
        filter!(x -> x != move[1], temp_solution.selectedLv1)
        # Adding the concentrator to the selected list
        push!(temp_solution.selectedLv1, move[2])
        # Updating the links from terminals to concentrators
        terminals_to_move = findall(x -> x == move[1], temp_solution.linksTerminalLevel1)
        for terminal in terminals_to_move
            temp_solution.linksTerminalLevel1[terminal] = closest_concentrators(temp_solution,data)[terminal]
        end
        # Updating the links from concentrators to concentrators
        # for i in concentrator_to_delete
        #     deleteat!(temp_solution.linksLevel1Level2, i)
        #     push!(temp_solution.linksLevel1Level2, closest_lv2_concentrators(temp_solution,data)[move[2]])
        # end
        # Check if the solution is feasible
        if isFeasible(temp_solution, data.C)
            # Check if the solution is better than the current solution
            if sol.valueObj1 > obj1(temp_solution, data)
                candidate_list = (obj1(temp_solution, data), move)
                improved_found = true
            end
        end
    end
    return candidate_list, possible_moves
end

# ------------------------------------------------------------------------
# Tabu search for the second objective
# ------------------------------------------------------------------------

function tabu_obj2(sol::solution, data::instance)
    # Parameters
    nbIter::Int64 = 10
    tabu_list::Vector{Tuple{Int64,Int64}} = []
    tabu_list_size::Int64 = 7
    iter::Int64 = 1
    no_more_candidates::Bool = false

    # Initialization
    current_solution::solution = deepcopy(sol)
    best_solution::solution = deepcopy(sol)

    # Tabu search
    while iter <= nbIter && !no_more_candidates
        best_move, possible_moves = choose_candidates_obj2(current_solution, data) # List of candidate moves
        if best_move[1] == 0
            no_more_candidates = true
            break
        else
            # check if the move is in tabu list
            while best_move[2] ∈ tabu_list
                best_move, possible_moves = choose_other_candidate_obj2(current_solution, data, possible_moves)
            end
            if best_move[1] == 0
                no_more_candidates = true
            else
                # update the current solution
                # concentrator_to_delete = findall(x -> x == best_move[2][1], current_solution.selectedLv1)
                filter!(x -> x != best_move[2][1], current_solution.selectedLv1)
                push!(current_solution.selectedLv1, best_move[2][2])
                terminals_to_move = findall(x -> x == best_move[2][1], current_solution.linksTerminalLevel1)
                for terminal in terminals_to_move
                    current_solution.linksTerminalLevel1[terminal] = closest_concentrators(current_solution,data)[terminal]
                end
                # for concentrator in concentrator_to_delete
                #     deleteat!(current_solution.linksLevel1Level2, concentrator)
                #     push!(current_solution.linksLevel1Level2, closest_lv2_concentrators(current_solution,data)[best_move[2][2]])
                # end
                current_solution.valueObj1 = obj1(current_solution, data)
                current_solution.valueObj2 = obj2(current_solution, data.c)
                # update the tabu list
                if length(tabu_list) >= tabu_list_size
                    popfirst!(tabu_list)
                end
                push!(tabu_list, best_move[2])
                if best_solution.valueObj2 > current_solution.valueObj2
                    best_solution = deepcopy(current_solution)
                end
            end
        end
        iter+=1
    end
    return best_solution
end

function choose_candidates_obj2(sol::solution, data::instance)
    candidate_list = (0, (0,0))
    # Get all the not selected concentrators
    not_selected_lv1_concentrators = setdiff(1:size(data.lv1Concentrators)[1], sol.selectedLv1)
    possible_moves = vec(collect(Iterators.product(sol.selectedLv1, not_selected_lv1_concentrators)))
    improved_found::Bool = false
    while !isempty(possible_moves) && !improved_found
        move = pop!(possible_moves)
        temp_solution = deepcopy(sol)
        # Deleting the concentrator from the selected list
        # concentrator_to_delete = findall(x -> x == move[1], temp_solution.selectedLv1)
        filter!(x -> x != move[1], temp_solution.selectedLv1)
        # Adding the concentrator to the selected list
        push!(temp_solution.selectedLv1, move[2])
        # Updating the links from terminals to concentrators
        terminals_to_move = findall(x -> x == move[1], temp_solution.linksTerminalLevel1)
        for terminal in terminals_to_move
            temp_solution.linksTerminalLevel1[terminal] = closest_concentrators(temp_solution,data)[terminal]
        end
        # Updating the links from concentrators to concentrators
        # for i in concentrator_to_delete
        #     deleteat!(temp_solution.linksLevel1Level2, i)
        #     push!(temp_solution.linksLevel1Level2, closest_lv2_concentrators(temp_solution,data)[move[2]])
        # end
        # Check if the solution is feasible
        if isFeasible(temp_solution, data.C)
            # Check if the solution is better than the current solution
            if sol.valueObj2 > obj2(temp_solution, data.c)
                candidate_list = (obj2(temp_solution, data.c), move)
                improved_found = true
            end
        end
    end
    return candidate_list, possible_moves
end

function choose_other_candidate_obj2(sol::solution, data::instance, possible_moves::Vector{Tuple{Int64,Int64}})
    candidate_list = (0, (0,0))
    improved_found::Bool = false
    while !isempty(possible_moves) && !improved_found
        move = pop!(possible_moves)
        temp_solution = deepcopy(sol)
        # Deleting the concentrator from the selected list
        # concentrator_to_delete = findall(x -> x == move[1], temp_solution.selectedLv1)
        filter!(x -> x != move[1], temp_solution.selectedLv1)
        # Adding the concentrator to the selected list
        push!(temp_solution.selectedLv1, move[2])
        # Updating the links from terminals to concentrators
        terminals_to_move = findall(x -> x == move[1], temp_solution.linksTerminalLevel1)
        for terminal in terminals_to_move
            temp_solution.linksTerminalLevel1[terminal] = closest_concentrators(temp_solution,data)[terminal]
        end
        # Updating the links from concentrators to concentrators
        # for i in concentrator_to_delete
        #     deleteat!(temp_solution.linksLevel1Level2, i)
        #     push!(temp_solution.linksLevel1Level2, closest_lv2_concentrators(temp_solution,data)[move[2]])
        # end
        # Check if the solution is feasible
        if isFeasible(temp_solution, data.C)
            # Check if the solution is better than the current solution
            if sol.valueObj2 > obj2(temp_solution, data.c)
                candidate_list = (obj2(temp_solution, data.c), move)
                improved_found = true
            end
        end
    end
    return candidate_list, possible_moves
end

# testing
# for i in 1:100
# data = loadInstance("data/small7.txt")
# println("Instance loaded")

# sol = @time grasp(data, 0.7)
# println("GRASP done")
# println(sol)

# sol = @time tabu(sol, data)
# println("Tabu done")
# println(sol)

# sol = @time tabu_obj2(sol, data)
# println("Tabu 2 done")
# println(sol)
# end