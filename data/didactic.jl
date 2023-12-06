# Sets: I: terminals,  J: first stage concentrators , K: second stage concentrators
I = 1:3
J = 1:3
K = 1:2

# Assignment costs of terminals to first stage concentrators (c_ij)
c = [
    5 8 6
    4 7 5
    6 9 7
]

# Connection costs between first and second stage concentrators (b_jk)
b = [
    10 8 
    15 13
    12 10
]

# Second stage concentrators setup costs (sk)
s = [20, 25]

println("Sets:")
println("I: ", I)
println("J: ", J)
println("K: ", K)

println("\nAssignment Costs (cij):")
println(c)

println("\nInstallation and Connection Costs (bjk):")
println(b)

println("\nSetup Costs (sk):")
println(s)