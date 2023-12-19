#===================================================================================================================================================================
                                                                Loading the instance
====================================================================================================================================================================
# File format:
    - The first line contains four integers, which corresponds to m(number of concentrators), n(number of locations), p and r (both not used in this project)
    - The next m lines contains information about the candidate location to host a concentrator (facility):
        Each line is conformed with two floats that identifies the x and y coordinates
    - The next n lines contains information about the demand points:
        Each line is conformed with two floats that identifies the x and y coordinates
    and an integer that represents the weight of the demand point (1 in all the examples)

=#


function loadInstance(fname::String)
    f=open(fname)
    # read of the first line
    m::Int64, n::Int64, p::Int64, r::Int64 = parse.(Int, split(readline(f)))

    # we want to divide the set of concentrators in two levels so:
    # we assign 4/5 to level 1 concentrators and 1/5 to level 2 concentrators
    ratio::Float32 = 4/5
    nLevel1::Int64 = (Int)(m*ratio)
    nLevel2::Int64 = m - nLevel1

    # read the location of the level1 concentrators
    lv1Concentrators=zeros(Float32, nLevel1, 2)
    for i=1:nLevel1
        values = split(readline(f))
        for j in 1:2
            coordinate = parse(Float32,values[j])
            lv1Concentrators[i,j]= coordinate
        end
    end

    # read the location of the level2 concentrators
    lv2Concentrators=zeros(Float32, nLevel2, 2)
    for i=1:nLevel2
        values = split(readline(f))
        for j in 1:2
            coordinate = parse(Float32,values[j])
            lv2Concentrators[i,j]= coordinate
        end
    end

    # read the location of the n demands
    terminals=zeros(Float32, n, 2)
    for i=1:n
        values = split(readline(f))
        for j in 1:2
            coordinate = parse(Float32,values[j])
            terminals[i,j]= coordinate
        end
    end

    close(f)

    # max number of concentrators at level 1 -> 2/3 of the number of concentrators at level 1
    C = floor(Int, 1/3 * nLevel1)

    # we generate the cost matrixes
    c = distancesTerminalsConcentrators(lv1Concentrators, terminals)
    b = distancesConcentrators(lv1Concentrators, lv2Concentrators)
    s = rand(minimum(b):maximum(b),nLevel2)

    return instance(m, n, nLevel1, nLevel2, lv1Concentrators, lv2Concentrators, terminals, C, c, b, s)
end


# ===================================================================================================================================================================#
#                                                            Computation of the data
#====================================================================================================================================================================#

# generate the distance matrix between concentrators
function distancesConcentrators(lv1Concentrators::Array{Float32,2}, lv2Concentrators::Array{Float32,2})
    l1::Int64 = size(lv1Concentrators,1)
    l2::Int64 = size(lv2Concentrators,1)
    distancesConcentrators = zeros(Int64, l1, l2)
    for i in 1:l1
        for j in 1:l2
            dist = (lv1Concentrators[i,1]-lv2Concentrators[j,1])^2 + (lv1Concentrators[i,2]-lv2Concentrators[j,2])^2
            dist = dist^0.5
            distancesConcentrators[i,j] = trunc(Int, dist)
        end
    end
    return distancesConcentrators
end

# generate the distance matrix between terminals and concentrators of first level
function distancesTerminalsConcentrators(concentrators::Array{Float32,2}, terminals::Array{Float32,2})
    m = size(concentrators,1)
    n = size(terminals,1)
    distancesTerminalsConcentrators = zeros(Int64, m, n)
    for i in 1:m
        for j in 1:n
            dist = (concentrators[i,1]-terminals[j,1])^2 + (concentrators[i,2]-terminals[j,2])^2
            dist = dist^0.5
            distancesTerminalsConcentrators[i,j] = trunc(Int, dist)
        end
    end
    return distancesTerminalsConcentrators
end