include("grasp.jl")
include("functions.jl")
include("parser.jl")

function tabu(sol::solution, data::instance)

    # Parameters
    nbIter::Int64 = 10
    tabu_list::Vector{Int64} = []
    # TODO : set the size of the tabu list
    iter::Int64 = 0

    # Initialization
    current_solution::solution = deepcopy(sol)
    best_solution::solution = deepcopy(sol)

    # Tabu search
    while iter < nbIter
        moves::Vector{Tuples{Int64,Int64}} = candidate_list(current_solution, data) # List of candidate moves
        obj1_values = Dict() # List of objective values, the key being the move
        for move ∈ moves
            if move ∉ tabu_list
                new_solution::solution = deepcopy(current_solution)
                new_solution.selectedLv1.delete!(move[1])
                new_solution.selectedLv1.push!(move[2])
                obj1_values[move] = obj1(new_solution, data)
            end
        end
        # Select the best move
        best_move = findmin(obj1_values)
        # Update the tabu list
        tabu_list.push!(best_move)[1]
        # Check if the new solution is better than the best known solution
        # TODO : change the input of obj1 function to suit the instance struct
        if obj1_values[best_move] < obj1(best_solution, data)
            best_solution = deepcopy(current_solution)
        end

    end
end

# Generates the current solution feasable neighbors
function candidate_list(sol::solution, data::instance)
    candidate_list = []
    # Get all the not selected concentrators
    not_selected_lv1_concentrators = setdiff(1:size(data.lv1Concentrators)[1], sol.selectedLv1)
    println("Selected concentrators : ", sort(sol.selectedLv1))
    println("Not selected concentrators : ", sort(not_selected_lv1_concentrators))
    possible_moves = collect(Iterators.product(sol.selectedLv1, not_selected_lv1_concentrators))
    println("Possible moves : ", possible_moves)
    println("Number of possible moves : ", length(possible_moves))
    # TODO: Il faut faire bouger les links  aussi !
    for move ∈ possible_moves
        temp_solution = deepcopy(sol)
        # Deleting the concentrator from the selected list
        filter!(x -> x != move[1], temp_solution.selectedLv1)
        # Adding the concentrator to the selected list
        push!(temp_solution.selectedLv1, move[2])
        # Updating the links from terminals to concentrators
        terminals_to_move = findall(x -> x == move[1], temp_solution.linksTerminalLevel1)
        for terminal in terminals_to_move
            temp_solution.linksTerminalLevel1[terminal] = move[2]
        end
        # Updating the links from concentrators to concentrators
        concentrators_to_move = findall(x -> x == move[1], temp_solution.linksLevel1Level2)
        for concentrator in concentrators_to_move
            temp_solution.linksLevel1Level2[concentrator] = move[2]
        end
        # Check if the solution is feasible
        if isFeasible(temp_solution, data.C)
            # Check if the solution is better than the current solution
            if sol.valueObj1 > obj1(temp_solution, data)
                # println("Better solution found regarding z1 ")
                push!(candidate_list, move)
            elseif sol.valueObj2 > obj2(temp_solution, data)
                # println("Better solution found regarding z2 ")
                push!(candidate_list, move)
            end
        end
    end
    return candidate_list
end

# testing
data = loadInstance("data/small1.txt")
println(typeof(data))
sol::solution = grasp(data)
println("GRASP done")
println("Objective 1 calculated : ", obj1(sol, data))
println("Objective 1 stored : ", sol.valueObj1)
cand = candidate_list(sol, data)
println("Candidate list : ", cand)
println("Number of candidates : ", length(cand))