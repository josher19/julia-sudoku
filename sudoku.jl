#!/usr/bin/env julia

# Experiment in using Julia (I language I revently discovered)
# to solve Sudoku puzzles, from scratch, without looking at other peoples
# solutions.

puzzle = [
            [5,3,0,0,7,0,0,0,0],
            [6,0,0,1,9,5,0,0,0],
            [0,9,8,0,0,0,0,6,0],
            [8,0,0,0,6,0,0,0,3],
            [4,0,0,8,0,3,0,0,1],
            [7,0,0,0,2,0,0,0,6],
            [0,6,0,0,0,0,2,8,0],
            [0,0,0,4,1,9,0,0,5],
            [0,0,0,0,8,0,0,7,9]];
            
# println(puzzle);

# println(join(puzzle[1], " "))
println(join(map(row -> join(row, " "), puzzle), ";\n"))

# println(puzzle[:][1])

grid = [
5 3 0 0 7 0 0 0 0;
6 0 0 1 9 5 0 0 0;
0 9 8 0 0 0 0 6 0;
8 0 0 0 6 0 0 0 3;
4 0 0 8 0 3 0 0 1;
7 0 0 0 2 0 0 0 6;
0 6 0 0 0 0 2 8 0;
0 0 0 4 1 9 0 0 5;
0 0 0 0 8 0 0 7 9]


# println(grid[:, 1])
# println(grid[1, :])

const GRID_SIZE = 9
ALL_POSSIBLE = BitSet(1:9)
possibles = fill(ALL_POSSIBLE, (GRID_SIZE, GRID_SIZE))
# println("SetDiff: ", setdiff(possibles[1, 1], BitSet(1:3)))

curry(f, x) = (xs...) -> f(x, xs...)
precurry(f, x) = (xs...) -> f(xs..., x)
# println(precurry(setdiff, BitSet(1))(possibles[1,1]))


const sqcol = const sqrow = [1:3, 4:6, 7:9]
function neighbors(r)
    return reduce(union, [row for row in sqrow if !(r in row)])
end

function mySet(r)
    BitSet([collect(row) for row in sqrow if r in row][1])
end

@assert(mySet(4) == BitSet([4, 5, 6]))
@assert(5 in mySet(4))

function mySquare(r)
    for row in sqrow
        if r in row
            return row
        end
    end
end

@assert(mySquare(4) == 4:6)

@assert(neighbors(8) == [1,2,3,4,5,6])

function bitmask(n, subset) 
    return subset .& (1 << n) .>> n
end


function column(n, g = grid)
    # return g[n*9-8:n*9]
    return g[:, n]
end

function row(n, g = grid)
    return g[n, :]
end

function squareFor(r, c, g = grid)
    g[mySquare(r), mySquare(c)]
end

@assert(row(2) == [6, 0, 0, 1, 9, 5, 0, 0, 0])
@assert(column(2) == [3, 0, 9, 0, 0, 0, 6, 0, 0])
@assert(squareFor(8,7) == [2 8 0; 0 0 5; 0 7 9])

function -(a::BitSet, b)
    setdiff(a, b)
end

# + = union for BitSets
import Base.+

function +(a::BitSet, b::BitSet)
    union(a, b)
end

# | = intersect for BitSets
import Base.|

function |(a::BitSet, b::BitSet)
    intersect(a, b)
end

function box(value, rows=3, cols=3)
    repeat([value], rows, cols)
end

notEmpty = x -> !isempty(x)

function findOnePossible(grid=grid, possibles=possibles, verbose=false)
    changed = Dict()
    for n in 1:9
        for r in 1:9
            foundSet = box(BitSet(n), 9, 1) .| possibles[r, 1:9]
            if filter(notEmpty, foundSet) == [BitSet(n)]
                ndx = findfirst(notEmpty, foundSet)
                c = first(ndx.I)
                if n in possibles[r, c]
                    key = "$(r)x$(c)"
                    changed[key] = "Setting $(r)x$(c) to $(n)"
                    setValue(n, r, c, possibles, grid)
                end
            end
            c = r
            foundSet = box(BitSet(n), 9, 1) .| possibles[1:9, c]
            if filter(notEmpty, foundSet) == [BitSet(n)]
                ndx = findfirst(notEmpty, foundSet)
                r = first(ndx.I)
                if n in possibles[r, c]
                    key = "$(r)x$(c)"
                    changed[key] = "Setting $(r)x$(c) to $(n)"
                    setValue(n, r, c, possibles, grid)
                end
            end
        end
    end
    if verbose
        print(changed)
    end
    changed
end

function findAllPossibles(grid=grid, possibles=possibles, verbose=false)
    while !isempty(findOnePossible(grid, possibles))
        if verbose
            printGrid(grid)
        else
            print(".")
        end
    end
    println("Done")
    printGrid(grid)
end

@assert((BitSet([1,2,3]) - BitSet(3))  - BitSet(1) == BitSet(2))
# println(possibles[1, 1] -= BitSet(9))

function eraseSquare(n, r, c, p=possibles)
    p[mySquare(r), mySquare(c)] .-= BitSet(n)
end

function eraseCol(n, r, c, p=possibles)
    p[r, neighbors(c)] .-= BitSet(n)
end

function eraseRow(n, r, c, p=possibles)
    p[neighbors(r), c] .-= BitSet(n)
end

function eraser(n, r, c, p=possibles)
    eraseSquare(n, r, c, p)
    eraseRow(n, r, c, p)
    eraseCol(n, r, c, p)
    p
end


# eraser(5, 1, 1)
# println(eraseSquare(3, 1, 1))
# println(eraseCol(3, 1, 1))
# items = eraseRow(3, 1, 1)[1]
# println(items)
# println(reduce(|, [p for p in map(i -> 2^i, items)]))

# Let BitSet handle converting Sets to Integers for us

# function toInt(items::BitSet{Int64})
#     powerz = map(i -> 2^i, items)
#     reduce(|, [p for p in powerz])
# end

# println(toInt(items))


function setValue(n, r, c, p=possibles, g=grid)
    if n > 0
        g[r, c] = n
        p[r, c] = BitSet()
        eraser(n, r, c, p)
    # else
    #     findSingles(g, [r], [c])
    # elseif length(p[r, c]) == 1
    #     # println([r, c, p[r, c]])
    #     return setValue(first(p[r, c]), r, c, p, g)
    end
end

# Initialize possibles from grid
function init(grid=grid, p=possibles)
    for c in 1:9
        for r in 1:9
            setValue(grid[r, c], r, c, p, grid)
        end
    end
end
# init()

# println(grid[4, 1], possibles[1:9, 1])

# println(length(possibles[8, 1]))

# p0 = possibles
# println(possibles)

# println(first(p0[8, 1]))

# println(squareFor(8,1))

# println(grid[8,1])

function printGrid(grid=grid)
    println("===") 
    for r in 1:9
        println(grid[r, 1:3], grid[r, 4:6], grid[r, 7:9])
        if r % 3 == 0
            println("---") 
        end
    end
end

function findPatterns(grid=grid, rows=1:9, cols=1:9, p=possibles)
    findSingles(grid, rows, cols, p)
end

function findLine(grid, rows=1:3:9, cols=1:3:9, p=possibles)
end

# Find patterns near and set value for cells with only one possible value
function findSingles(grid=grid, rows=1:9, cols=1:9, p=possibles)
    for r in rows
        for c in cols
            if grid[r, c] == 0 && length(p[r, c]) == 1
                # println([first(p[r, c]), r, c])
                setValue(first(p[r, c]), r, c, p, grid)
                # findPatterns(grid, mySquare(r), cols, p)
                # findPatterns(grid, rows, mySquare(c), p)
                findPatterns(grid, rows, [c], p)
                findPatterns(grid, [r], cols, p)
                findPatterns(grid, mySquare(r), mySquare(c), p)
            end
        end
    end
end

# println("0 Grid: ", grid[1:3, 1:3] .== 0)

# first pass simple solve
function solve(grid, p=possibles)
    println("INITIAL")
    init(grid, p)
    printGrid(grid)
    findPatterns(grid, 1:9, 1:9, p)
    findPatterns(grid, 1:9, 1:9, p)
    println("FINAL")
    printGrid(grid)
    println("0 Grid: ", any(grid[1:9, 1:9] .== 0))
    return grid
end

# println(join(map(row -> join(row, "\n"), grid), "")


# setValue(0, 8, 1)
# guessValue(8, 1) == 2
# println([possibles[r, c] if length(possibles[r, c] == 1) for c in 1:9, r in 1:9 ])


answerMatrix = [
 [5,3,4,6,7,8,9,1,2],
 [6,7,2,1,9,5,3,4,8],
 [1,9,8,3,4,2,5,6,7],
 [8,5,9,7,6,1,4,2,3],
 [4,2,6,8,5,3,7,9,1],
 [7,1,3,9,2,4,8,5,6],
 [9,6,1,5,3,7,2,8,4],
 [2,8,7,4,1,9,6,3,5],
 [3,4,5,2,8,6,1,7,9]]

# println("Answer Matrix")
# println(join(map(row -> join(row, " "), answerMatrix), ";\n"))

answerGrid = [
5 3 4 6 7 8 9 1 2;
6 7 2 1 9 5 3 4 8;
1 9 8 3 4 2 5 6 7;
8 5 9 7 6 1 4 2 3;
4 2 6 8 5 3 7 9 1;
7 1 3 9 2 4 8 5 6;
9 6 1 5 3 7 2 8 4;
2 8 7 4 1 9 6 3 5;
3 4 5 2 8 6 1 7 9]

answered = @time solve(grid) == answerGrid

println("Answered: ", answered)

puzzle2 = [ 5 0 0  0 0 4  1 0 0;
            0 4 6  0 0 9  0 0 0;
            9 0 1  0 6 0  8 3 4;

            7 0 5  0 4 3  0 1 0;
            0 0 4  0 8 0  3 0 0;
            0 1 0  6 5 0  4 0 9;

            1 8 2  0 7 0  9 0 3;
            0 0 0  1 0 0  5 4 0;
            0 0 7  3 0 0  0 0 1]

puzzle1 = grid
grid = puzzle2

# Simple Solve and then find all possible solutions
function solveAll(grid, p=fill(ALL_POSSIBLE, (GRID_SIZE, GRID_SIZE)), verbose=false)
    global possibles = p
    println(grid)
    @time solve(grid, p)
    if verbose
        printGrid(p)
    end
    printGrid(grid)
    @time findAllPossibles(grid, p, verbose)
    if verbose
        printGrid(p)
    end
    printGrid(grid)
    check_solved = isSolved(grid)
    println("Is Solved: $(check_solved)")
end

# Check that every row, column, and square has values 1 to 9.
function isSolved(grid)
    if any(grid .== 0)
        return false
    end
    fullSet = BitSet(1:9)
    for n in 1:9
        if BitSet(grid[n, 1:9]) != fullSet || BitSet(grid[1:9, n]) != fullSet
            return false
        end
    end
    for rowSq in [1:3, 4:6, 7:9]
        for colSq in [1:3, 4:6, 7:9]
            if BitSet(grid[rowSq, colSq]) != fullSet
                return false
            end
        end
    end
    return true
end


solveAll(grid)

grid = [
    0 0 0  9 7 0  0 0 6;
    0 7 0  0 0 6  8 0 1;
    0 0 2  0 8 3  0 0 0;

    0 8 6  0 2 0  0 0 0;
    0 0 1  0 9 0  6 0 0;
    0 0 0  0 3 0  2 4 0;

    0 0 0  7 4 0  1 0 0;
    9 0 4  8 0 0  0 6 0;
    7 0 0  0 6 9  0 0 0
]

solveAll(grid)

# TODO: Enter your own Sudoku
