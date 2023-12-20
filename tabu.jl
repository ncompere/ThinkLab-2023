include("grasp.jl")
include("functions.jl")
include("parser.jl")

function tabu(sol::solution, data::instance)

    # Parameters
    nbIter::Int64 = 10
    tabu_list::Vector{Tuple{Int64,Int64}} = []
    tabu_list_size::Int64 = 7
    iter::Int64 = 1

    # Initialization
    current_solution::solution = deepcopy(sol)
    best_solution::solution = deepcopy(sol)

    # testing
    # ------------------
    # moves = choose_candidates(current_solution, data)
    # println("Moves : ", moves)
    # best_move = findmin(moves)
    # println("Best move : ", best_move)
    # ------------------

    # Tabu search
    while iter <= nbIter
        # println("Iteration : ", iter)
        moves = choose_candidates(current_solution, data) # List of candidate moves
        if isempty(moves)
            println("No more candidates")
            break
        else
            # choose the best move
            best_move = findmin(moves)
            # println("Best move : ", best_move)
            # check if the move is in tabu list
            while best_move[2] ∈ tabu_list  && !isempty(moves)
                # println("Move in tabu list")
                delete!(moves, best_move[2])
                best_move = findmin(moves)
                # println("Updated best move : ", best_move)
            end
            # update the current solution
            concentrator_to_delete = findall(x -> x == best_move[2][1], current_solution.selectedLv1)
            filter!(x -> x != best_move[2][1], current_solution.selectedLv1)
            push!(current_solution.selectedLv1, best_move[2][2])
            terminals_to_move = findall(x -> x == best_move[2][1], current_solution.linksTerminalLevel1)
            for terminal in terminals_to_move
                current_solution.linksTerminalLevel1[terminal] = closest_concentrators(current_solution,data)[terminal]
            end
            for concentrator in concentrator_to_delete
                deleteat!(current_solution.linksLevel1Level2, concentrator)
                push!(current_solution.linksLevel1Level2, closest_lv2_concentrators(current_solution,data)[best_move[2][2]])
            end
            current_solution.valueObj1 = obj1(current_solution, data)
            # println("Current solution value : ", current_solution.valueObj1)
            current_solution.valueObj2 = obj2(current_solution, data.c)
            # update the tabu list
            if length(tabu_list) >= tabu_list_size
                popfirst!(tabu_list)
            end
            push!(tabu_list, best_move[2])
            # println("Tabu list : ", tabu_list)
            # update the best solution
            # println("Best solution value : ", best_solution.valueObj1)
            # println("Current solution value : ", current_solution.valueObj1)
            if best_solution.valueObj1 > current_solution.valueObj1
                # println("Better solution found")
                best_solution = deepcopy(current_solution)
            end
        end
        iter+=1
    end
    return best_solution
end

# Generates the current solution feasable neighbors
function choose_candidates(sol::solution, data::instance)
    candidate_list = Dict()
    # Get all the not selected concentrators
    not_selected_lv1_concentrators = setdiff(1:size(data.lv1Concentrators)[1], sol.selectedLv1)
    # println("Selected concentrators : ", sort(sol.selectedLv1))
    # println("Not selected concentrators : ", sort(not_selected_lv1_concentrators))
    possible_moves = collect(Iterators.product(sol.selectedLv1, not_selected_lv1_concentrators))
    # println("Possible moves : ", possible_moves)
    # println("Number of possible moves : ", length(possible_moves))
    for move ∈ possible_moves
        # println("Move : ", move)
        temp_solution = deepcopy(sol)
        # Deleting the concentrator from the selected list
        concentrator_to_delete = findall(x -> x == move[1], temp_solution.selectedLv1)
        # println("Concentrator to delete : ", concentrator_to_delete)
        # println("Selected concentrators : ", temp_solution.selectedLv1)
        filter!(x -> x != move[1], temp_solution.selectedLv1)
        # println("Selected concentrators after delete : ", temp_solution.selectedLv1)
        # Adding the concentrator to the selected list
        push!(temp_solution.selectedLv1, move[2])
        # println("Selected concentrators after add : ", temp_solution.selectedLv1)
        # Updating the links from terminals to concentrators
        terminals_to_move = findall(x -> x == move[1], temp_solution.linksTerminalLevel1)
        # println("Terminals to move : ", terminals_to_move)
        # println("Terminal links before shift : ", temp_solution.linksTerminalLevel1)
        for terminal in terminals_to_move
            temp_solution.linksTerminalLevel1[terminal] = closest_concentrators(temp_solution,data)[terminal]
        end
        # println("Terminal links after shift : ", temp_solution.linksTerminalLevel1)
        # Updating the links from concentrators to concentrators
        for i in concentrator_to_delete
            # println("Concentrator links before shift : ", temp_solution.linksLevel1Level2)
            deleteat!(temp_solution.linksLevel1Level2, i)
            # println("Concentrator links after delete : ", temp_solution.linksLevel1Level2)
            push!(temp_solution.linksLevel1Level2, closest_lv2_concentrators(temp_solution,data)[move[2]])
            # println("Concentrator links after add : ", temp_solution.linksLevel1Level2)
        end
        # Check if the solution is feasible
        if isFeasible(temp_solution, data.C)
            # println("Feasible solution")
            # Check if the solution is better than the current solution
            # if sol.valueObj1 > obj1(temp_solution, data)
                # println("Better solution found regarding z1 ")
                # push!(candidate_list, move)
                candidate_list[move] = obj1(temp_solution, data)
            # elseif sol.valueObj2 > obj2(temp_solution, data.c)
            #     # println("Better solution found regarding z2 ")
            #     push!(candidate_list, move)
            #     candidate_list[move] = obj2(temp_solution, data.c)
            # end
        end
    end
    return candidate_list
end

# testing
# data = loadInstance("data/small1.txt")
# # println(typeof(data))
# sol = @time grasp(data)
# println("GRASP done")
# println("GRASP solution : ", sol)

# # # cand = @time choose_candidates(sol, data)
# # # println("Candidate list : ", cand)
# # # println("Number of candidates : ", length(cand))
# sol = @time tabu(sol, data)
# println("Tabu solution : ", sol)