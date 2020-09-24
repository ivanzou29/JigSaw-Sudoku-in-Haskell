import System.IO
import Data.Char
import Data.List
import System.Random

-- main function
main :: IO()
main = 
    do  putStrLn "Hello! Welcome to Jigsaw Sudoku developed by Yunfan Zou."
        putStrLn "Do you want to load an existing board or randomly generate a board?"
        putStrLn "1: for loading an existing board from a file"
        putStrLn "2: for generating a random board"
        choice <- getLine
        if (choice == "1") then jigsawSudoku
        else if (choice == "2") then generateBoard
        else 
            do  putStrLn "You have entered an invalid command. Please enter again!"
                putStrLn "-----------------------------------------------"
                main

-- randomly generate a board
generateBoard :: IO()
generateBoard =
    do  putStrLn "Please give your new board a name:"
        boardName <- getLine
        let boardPath = boardName ++ ".txt"
        putStrLn "-----------------------------------------------"
        putStrLn "The system is now generating your board, it is going to take around 1 to 2 minutes."
        rand <- randomRIO (0, 2 :: Int)
        putStrLn "------------Generating-sudoku-----------------"
        let blockInfoList = randomBlockInfoList !! rand
        randStarting <- randomRIO (1, 9 :: Int)
        let empty = (0, 0)
        let hint = [intToDigit randStarting]
        let solution = solverBacktrackNaive blockInfoList (replicate 9 ".........") empty hint
        
        numsToHide <- randomRIO(50, 70)
        indexList <- listRandom numsToHide []
        let filledNumInfoList = removePartial indexList solution
        saveBoard blockInfoList filledNumInfoList boardPath
        displayBoard blockInfoList filledNumInfoList
        playJigsawSudoku blockInfoList filledNumInfoList boardPath [] []



-- load board and provide user prompt
jigsawSudoku :: IO()
jigsawSudoku = 
    do  putStrLn "Enter a file path to load the sudoku board:"
        filepath <- getLine
        loadMap filepath
    

-- read the map and print it to the console
-- argument is the file path to the file storing the inforamtion of the board
loadMap :: FilePath -> IO()
loadMap filepath  = do  contents <- readFile filepath
                        let fileLines = lines contents
                        let (blockInfoList, filledNumInfoList) = splitInfoLines fileLines
                        putStrLn "-----------------------------------------------"
                        putStrLn "Read board successfully!"
                        putStrLn "Initial board:"
                        displayBoard blockInfoList filledNumInfoList
                        playJigsawSudoku blockInfoList filledNumInfoList filepath [] []

-- play function, ask the user to input different operations
-- first argument is the block information list
-- second argument is the filled numbers information list
-- third argument is the file path storing the board
-- fourth argument is the list of previous states represented in filled numbers information
-- fifth argument is the list of succeeding states represented in filled numbers information
playJigsawSudoku :: [String] -> [String] -> String -> [[String]] -> [[String]] ->IO()
playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding = 
    do  putStrLn "What do you want to do next? Here are the options for you."
        putStrLn "S: for directly solve"
        putStrLn "1: for a next move"
        putStrLn "2: to save the current board"
        putStrLn "3: to quit the game"
        putStrLn "4: to get a hint for a next move"
        if (length previous /= 0) then putStrLn "5: Undo operation" else putStr ""
        if (length succeeding /= 0) then putStrLn "6: Redo operation" else putStr ""
        putStrLn "Please enter a number for your option:"
        command <- getLine
        if (command == "S") then
            do
                putStrLn "-------------------Solving...------------------"
                let empty = getNextEmpty filledNumInfoList (0, -1)
                let hints = getHintsFromCoordinate blockInfoList filledNumInfoList empty
                let solution = solverBacktrackNaive blockInfoList filledNumInfoList empty hints

                if (length solution == 0) then putStrLn "Sorry, no solution could be found for this board."
                else displayBoard blockInfoList solution

        else if (command == "1") then
            do  putStrLn "Next move:"
                putStrLn "Row:"
                rowStr <- getLine
                putStrLn "Column:"
                columnStr <- getLine
                putStrLn "Number:"
                numStr <- getLine
                if (moveValid blockInfoList filledNumInfoList (naturalFrom rowStr) (naturalFrom columnStr) (head numStr)) then
                    do  putStrLn "-----------------------------------------------"
                        putStrLn "New board:"
                        let filledNumInfoListAfterMove = makeMove filledNumInfoList (naturalFrom rowStr) (naturalFrom columnStr) (head numStr)
                        displayBoard blockInfoList filledNumInfoListAfterMove
                        if (checkEnding filledNumInfoListAfterMove) then
                            if (checkWin blockInfoList filledNumInfoListAfterMove) then
                                do  putStrLn "Congratulations! You win the game!"
                            else
                                do  putStrLn "Sorry. You lose the game."
                        else
                            do  playJigsawSudoku blockInfoList filledNumInfoListAfterMove filepath (previous ++ [filledNumInfoList]) []
                else
                    do  putStrLn "Sorry, there is a conflict existing in your board."
                        putStrLn "-----------------------------------------------"
                        putStrLn "Your current board:"
                        displayBoard blockInfoList filledNumInfoList
                        playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding
        else if (command == "2") then 
            do  saveBoard blockInfoList filledNumInfoList filepath
                playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding
        else if (command == "3") then putStrLn "Bye! See you next time!"
        else if (command == "4") then
            do  let hints = getNextHint blockInfoList filledNumInfoList
                if (length hints /= 0) then
                    do  randIndex <- randomRIO (0, (length hints - 1) :: Int)
                        let (x, y, c) = hints !! randIndex
                        putStrLn "----------------Here-is-the-hint---------------"
                        putStrLn "Let's go for the following location:"
                        let rowStr = "Row: " ++ [intToDigit x]
                        let columnStr = "Column: " ++ [intToDigit y]
                        let numberStr = "Number: " ++ [c]
                        putStrLn rowStr
                        putStrLn columnStr
                        putStrLn numberStr
                        putStrLn "-----------------------------------------------"
                        playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding
                else
                    do
                        putStrLn "-----------------------------------------------"
                        putStrLn "Sorry. You do not have any options to fill the next grid now. (Maybe you could try undo a few steps?)"
                        putStrLn "-----------------------------------------------"
                        playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding



        else if (command == "5") then
            do  if (length previous /= 0) then
                    do  putStrLn "Undo finished."
                        putStrLn "-----------------------------------------------"
                        putStrLn "Your current board:"
                        displayBoard blockInfoList (last previous)
                        playJigsawSudoku blockInfoList (last previous) filepath (take (length previous - 1) previous) (succeeding ++ [filledNumInfoList])
                else
                    do  putStrLn "You have entered an invalid command. Please enter again!"
                        putStrLn "-----------------------------------------------"
                        playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding
        else if (command == "6") then
            do if (length succeeding /= 0) then
                    do  putStrLn "Redo finished."
                        putStrLn "-----------------------------------------------"
                        putStrLn "Your current board:"
                        displayBoard blockInfoList (last succeeding)
                        playJigsawSudoku blockInfoList (last succeeding) filepath (previous ++ [filledNumInfoList]) (take (length succeeding - 1) succeeding)
                else
                    do  putStrLn "You have entered an invalid command. Please enter again!"
                        putStrLn "-----------------------------------------------"
                        playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding
        else 
            do  putStrLn "You have entered an invalid command. Please enter again!"
                putStrLn "-----------------------------------------------"
                playJigsawSudoku blockInfoList filledNumInfoList filepath previous succeeding

-- display the board
-- first argument is the block information list
-- second argument is the filled numbers information list
displayBoard :: [String] -> [String] -> IO()
displayBoard blockInfoList filledNumInfoList =
    do  let board = constructEmptyBoard
        let boardWithBorder = drawBlockBorder board blockInfoList
        let boardWithNumLoaded = loadNumbers 0 boardWithBorder filledNumInfoList
        putStr (showBoard boardWithNumLoaded)

-- save the board to a destination
-- first argument is the block information list
-- second argument is the filled numbers information list
-- third argument is the filepath of the destination
saveBoard :: [String] -> [String] -> FilePath -> IO()
saveBoard blockInfoList filledNumInfoList destination = 
    do  let infoString = concatInfoLines blockInfoList filledNumInfoList
        writeFile destination infoString
        putStrLn "Your board has been saved!"
        putStrLn "-----------------------------------------------"

-- make move function
-- first argument is the filled number info list
-- second argument is the row number
-- third argument is the column number
-- fourth argument is a character of the digit to fill in
-- will get the new filled number info list after filling in the number
makeMove :: [String] -> Int -> Int -> Char -> [String]
makeMove filledNumInfoList row column numChar =
    replaceAt row (replaceAt column numChar (filledNumInfoList !! row)) filledNumInfoList

-- check move valid function
-- first argument is the block info list
-- second argument is the filled number info list
-- third argument is the row number
-- fourth argument is the column number
-- fifth argument is a character of the digit to fill in
-- will get the boolean value of whether the intended move is valid or not
moveValid :: [String] -> [String] -> Int -> Int -> Char -> Bool
moveValid blockInfoList filledNumInfoList row column numChar =
    (rowConstraintSatisfied filledNumInfoList row numChar) &&
    (columnConstraintSatisfied filledNumInfoList column numChar) &&
    (blockConstraintSatisfied blockInfoList filledNumInfoList row column numChar)

-- check ending
-- argument is the filled number info list
checkEnding :: [String] -> Bool
checkEnding xss = and ['.' `notElem` row | row <- xss]
-- check win
-- first argument is the block information list
-- second argument is the filled numbers information list
checkWin :: [String] -> [String] -> Bool
checkWin blockInfoList filledNumInfoList = 
    (and [checkPortion row | row <- filledNumInfoList]) && (and [checkPortion column | column <- (transpose filledNumInfoList)])
    && (and [checkPortion block | block <- [findBlockElems n (zip (concat blockInfoList) (concat filledNumInfoList)) | n <- "012345678"]])


-- concat the two information lists into one single string
-- first argument is the block information list
-- second argument is the filled numbers information list
concatInfoLines :: [String] -> [String] -> String
concatInfoLines blockInfoList filledNumInfoList = concat [line ++ "\n" | line <- (blockInfoList ++ filledNumInfoList)]

-- split the lines into two parts to support the information of blocks and numbers
-- argument are the lines of file content
splitInfoLines :: [String] -> ([String], [String])
splitInfoLines contents = (take 9 contents, drop 9 contents)

-- construct the empty board for UI display
constructEmptyBoard :: [String]
constructEmptyBoard = 
    ["." ++ replicate 35 '-' ++ "."] ++ concat (replicate 8 ["| " ++ concat (replicate 8 ".   ") ++ ". |",  "|" ++ replicate 35 ' ' ++ "|"])
    ++ ["| " ++ concat (replicate 8 ".   ") ++ "' |"] ++ ["'" ++ replicate 35 '-' ++ "'"]

-- draw the border between the blocks based on block information
-- first argument is an empty board
-- second argument is the block info list
drawBlockBorder :: [String] -> [String] -> [String]
drawBlockBorder board blockInfoList =  refineBoardBorder (transpose (drawColumnBorder 0 (transpose (drawRowBorder 0 board blockInfoList)) (transpose blockInfoList)))

-- load numbers
-- first argument is an int recording the current index in filled number info list
-- second argument is the board with border
-- third argument is the filled number info list
loadNumbers :: Int -> [String] -> [String] -> [String]
loadNumbers n board [] = [board !! (2*n)]
loadNumbers n board (xs:xss) =  
    replaceAt 1 (multipleReplace (map ((+2).(*4)) [0..8]) xs (board !! (2*n+1))) ([board !! (2*n)] ++ [board !! (2*n+1)]) ++ loadNumbers (n+1) board xss

-- draw row border based on block information list
-- first argument is the number of rows defined in the board (from 0 to 8)
-- second argument is the board display list (19 * 37)
-- third argument is the block information list
drawRowBorder :: Int -> [String] -> [String] -> [String]
drawRowBorder n board [] = board
drawRowBorder n board xs = 
    drawRowBorder (n+1) (multipleReplace [2*n, 2*n + 1, 2*n + 2] 
    [drawSingleRowBorder (board !! (2*n)) (findVariation 0 (head xs)) '.',
    drawSingleRowBorder (board !! (2*n + 1)) (findVariation 0 (head xs)) '|',
    drawSingleRowBorder (board !! (2*n + 2)) (findVariation 0 (head xs)) '\''] 
    board) (drop 1 xs)

-- draw column border based on block information list
-- first argument is the number of columns defined in the board (from 0 to 8)
-- second argument is transpose of the board display list (37 * 19)
-- third argument is transpose of the block information list
-- output will not be transposed back
drawColumnBorder :: Int -> [String] -> [String] -> [String]
drawColumnBorder n board [] = board
drawColumnBorder n board xs = 
    drawColumnBorder (n+1) (multipleReplace [4*n, 4*n + 1, 4*n + 2, 4*n + 3, 4*n + 4] 
    [drawSingleColumnBorder (board !! (4*n)) (findVariation 0 (head xs)) (if n == 0 then ':' else ' '),
    drawSingleColumnBorder (board !! (4*n + 1)) (findVariation 0 (head xs)) '-',
    drawSingleColumnBorder (board !! (4*n + 2)) (findVariation 0 (head xs)) '-',
    drawSingleColumnBorder (board !! (4*n + 3)) (findVariation 0 (head xs)) '-',
    drawSingleColumnBorder (board !! (4*n + 4)) (findVariation 0 (head xs)) (if n == 8 then ':' else ' ')]
     board) (drop 1 xs)


-- draw row border for a single row
-- first argument is the displayed row, here we only take the 2nd, 4th, 6th, ..., 16th, 18th rows into consideration
-- second argument are the locations of borders along this row
-- third argument is the character for replacement
drawSingleRowBorder :: String -> [Int] -> Char -> String
drawSingleRowBorder row [] _ = row
drawSingleRowBorder row (x:xs) c = drawSingleRowBorder (replaceAt (4 * x) c row) xs c

-- draw column border for a single column
-- first argument is the displayed column
-- second argument are the locations of borders along this column
-- third argument is the character for replacement
drawSingleColumnBorder :: String -> [Int] -> Char ->String
drawSingleColumnBorder column [] _ = column
drawSingleColumnBorder column (x:xs) c = drawSingleColumnBorder (replaceAt (2 * x) c column) xs c

-- replace the nth element in a list with a new element
-- first argument is the location to replace
-- second argument is the new element
-- third argument is the list
replaceAt :: Int -> a -> [a] -> [a]
replaceAt _ _ [] = []
replaceAt n newElem (x:xs)
    | n == 0 = (newElem:xs)
    | otherwise = [x] ++ replaceAt (n-1) newElem xs

-- multiple replace at function
-- first argument are the locations to replace
-- second argument are the new elements
-- third argument is the list
multipleReplace :: [Int] -> [a] -> [a] -> [a]
multipleReplace [] [] ns = ns
multipleReplace (i:is) (x:xs) ns = multipleReplace is xs (replaceAt i x ns) 

-- find all variation points(location of border) of a list of int
-- first arguement is the current index in the list
-- second argument is the list
findVariation :: Int -> String -> [Int]
findVariation n [] = []
findVariation n [x] = []
findVariation n (x:xs)
            | x == head xs = findVariation (n+1) xs
            | otherwise = [n+1] ++ findVariation (n+1) xs

-- refine board with border
-- argument is the displayed board with border
refineBoardBorder :: [String] -> [String]
refineBoardBorder board = [refineRowBorder row | row <- columnRefinedBoard]
    where columnRefinedBoard = transpose [refineColumnBorder column | column <- (transpose board)]

-- refine column border
-- argument is the column
refineColumnBorder :: String -> String
refineColumnBorder [] = ""
refineColumnBorder [x] = [x]
refineColumnBorder [x,y] = [x,y]
refineColumnBorder (x:y:xs)
            | (y == ' ') && (x == '|') && ((head xs) == '|') = [x] ++ (refineColumnBorder (':':xs))
            | (y == ' ') && (x == '|') && ((head xs) == ' ') = [x] ++ (refineColumnBorder ('\'':xs))
            | (y == ' ') && (x == ' ') && ((head xs) == '|') = [x] ++ (refineColumnBorder ('.':xs))
            | (y == '.') && (x == '|') && ((head xs) == '|') = [x] ++ (refineColumnBorder ('|':xs))
            | otherwise = [x] ++ refineColumnBorder (y:xs)

-- refine row border
-- argument is the row
refineRowBorder :: String -> String
refineRowBorder [] = ""
refineRowBorder [x] = [x]
refineRowBorder [x,y] = [x,y]
refineRowBorder (x:y:xs)
            | (y == ' ') && (x == '-') && ((head xs) == '-') = [x] ++ (refineRowBorder ('-':xs))
            | otherwise = [x] ++ refineRowBorder (y:xs)

-- show the board as a string
-- the argument is the board display list (19 * 37)
showBoard :: [String] -> String
showBoard board = concat [row ++ "\n"| row <- board]

-- get int input from string
-- the argument is a string containing only one digit character
naturalFrom :: String -> Int
naturalFrom numStr = digitToInt (head numStr)

-- check row constraint
-- first argument is the filled number info list
-- second argument is the number of row
-- third argument is the number character
-- will get the boolean value of whether the row constraint is satisfied
rowConstraintSatisfied :: [String] -> Int -> Char -> Bool
rowConstraintSatisfied filledNumInfoList row numChar = not (elem numChar (filledNumInfoList !! row))

-- check column constraint
-- first argument is the filled number info list
-- second argument is the number of column
-- third argument is the number character
-- will get the boolean value of whether the column constraint is satisfied
columnConstraintSatisfied :: [String] -> Int -> Char -> Bool
columnConstraintSatisfied filledNumInfoList column numChar = not (elem numChar ((transpose filledNumInfoList) !! column))

-- check block constraint
-- first argument is the block info list
-- second argument is the filled number info list
-- third argument is the row number
-- fourth argument is the column number
-- fifth argument is a character of the digit to fill in
-- will get the boolean value of whether the block constraint is satisfied
blockConstraintSatisfied :: [String] -> [String] -> Int -> Int -> Char -> Bool
blockConstraintSatisfied blockInfoList filledNumInfoList row column numChar = 
    not (elem numChar (getBlockElements blockInfoList filledNumInfoList row column))


-- get the filled block list by coordinate
-- first argument is the block info list
-- second argument is the filled number info list
-- third argument is the row number
-- fourth argument is the column number
getBlockElements :: [String] -> [String] -> Int -> Int -> [Char]
getBlockElements blockInfoList filledNumInfoList row column =
    do  let b = getBlockNumber blockInfoList row column
        [filledNumInfoList !! x !! y | (x, y) <- getBlockCoordinates blockInfoList b]

-- get the block number by coordinate
-- first argument is the block info list
-- second argument is the row number
-- third argument is the column number
getBlockNumber :: [String] -> Int -> Int -> Char
getBlockNumber blockInfoList row column = blockInfoList !! row !! column

-- get block coordinates by block number
-- first argument is the block info list
-- second argument is the block number
getBlockCoordinates :: [String] -> Char -> [(Int, Int)]
getBlockCoordinates blockInfoList blockNum = [(x, y) | x <- [0..8], y <- [0..8], (blockInfoList !! x !! y) == blockNum]

-- check a portion contains all 9 numbers
-- argument is a row from the map
checkPortion :: String -> Bool
checkPortion portion = and [elem num portion | num <- "123456789"]

-- find block elements from the zipped info list
-- first argument is the char of the block number
-- second argument is the zipped list
findBlockElems :: Char -> [(Char, Char)] -> String
findBlockElems _ [] = []
findBlockElems c ((b, e):xs)
            | c == b = [e] ++ findBlockElems c xs
            | otherwise = findBlockElems c xs

-- get a hint for the next empty grid from current board
-- first argument is the block info list
-- second argument is the filled number info list
getNextHint :: [String] -> [String] -> [(Int, Int, Char)]
getNextHint blockInfoList filledNumInfoList = 
    [(x, y, c) | c <- "123456789", moveValid blockInfoList filledNumInfoList x y c]
    where (x, y) = getNextEmpty filledNumInfoList (0, -1)

-- get a hint for a grid given its coordinates
-- first argument is the block info list
-- second argument is the filled number info list
-- third argument is (x, y) coordnate

getHintsFromCoordinate :: [String] -> [String] -> (Int, Int) -> [Char]
getHintsFromCoordinate blockInfoList filledNumInfoList (x, y) = [c | c <- "123456789", moveValid blockInfoList filledNumInfoList x y c]

-- get the next empty coordinate
-- argument is the filled number info list
getNextEmpty :: [String] -> (Int, Int) -> (Int, Int)
getNextEmpty filledNumInfoList (x, y)
    | y /= 8 = if (filledNumInfoList !! x !! (y+1) == '.') then (x, y+1) else getNextEmpty filledNumInfoList (x, y+1)
    | y == 8 && x /= 8 = if (filledNumInfoList !! (x+1) !! 0 == '.') then (x+1, 0) else getNextEmpty filledNumInfoList (x+1, 0)
    | y == 8 && x == 8 = (-1, -1)

-- get all empty coordinates
-- argument is the filled number info list
getAllEmpty :: [String] -> [(Int, Int)]
getAllEmpty filledNumInfoList = [(x, y) | x <- [0..8], y <- [0..8], (filledNumInfoList !! x) !! y == '.']

-- check global all choices and sort, to get the coordinate with least number of choices
-- first argument is the block info list
-- second argument is the filled number info list
-- third argument is the set of visited maps
checkAndSortGlobalAllChoices :: [String] -> [String] -> [(Int, Int)]
checkAndSortGlobalAllChoices blockInfoList filledNumInfoList = 
    [(x, y) | (l, x, y) <- sort [(length (getHintsFromCoordinate blockInfoList filledNumInfoList (x, y)), x, y) | (x, y) <- getAllEmpty filledNumInfoList]]


-- a naive backtracking solver to solve the sudoku
-- first argument is the block info list
-- second argument is the filled number info list
-- third argument is the coordinate of the next index
-- fourth argument is the 
solverBacktrackNaive :: [String] -> [String] -> (Int, Int) -> [Char] -> [String]
solverBacktrackNaive blockInfoList filledNumInfoList empty hints =
    if (length hints /= 0) then
        do  let (nextX, nextY) = empty
            let nextFilledNumInfoList = makeMove filledNumInfoList nextX nextY (head hints)
            let nextEmpty = getNextEmpty filledNumInfoList (nextX, nextY)
            if (nextEmpty == (-1, -1)) then
                if checkWin blockInfoList nextFilledNumInfoList then nextFilledNumInfoList
                else []
            else
                do  let nextHints = getHintsFromCoordinate blockInfoList nextFilledNumInfoList nextEmpty
                    let sol = solverBacktrackNaive blockInfoList nextFilledNumInfoList nextEmpty nextHints 
                    if (sol == []) then solverBacktrackNaive blockInfoList filledNumInfoList (nextX, nextY) (drop 1 hints) else sol
    else []

-- generate a random block information list
randomBlockInfoList :: [[String]]
randomBlockInfoList = [
    ["000011222", "000111122", "300111222", "334444552", "333445555", "336444555", "366777888", "666778888", "666777788"],
    ["000011122", "000111122", "030112222", "334444255", "336445555", "336444555", "336778888", "666777788", "666777888"],
    ["000111122", "000111122", "030012222", "334444255", "333445555", "366444585", "336777885", "666677888", "667777888"]]

-- generate a list of random numbers between 0 ~ 80
-- the argument is the length of the list
-- the second argument is the list
listRandom :: Int -> [Int] -> IO([Int])
listRandom 0 xs = return xs
listRandom n xs = 
    do  rand <- randomRIO(0, 80 :: Int)
        listRandom (n-1) (xs ++ [rand])

-- remove some grids from a 
-- first argument is the list of index numbers to remove
-- second argument is the solution
removePartial :: [Int] -> [String] -> [String]
removePartial [] table = table
removePartial (x:xs) table =
    removePartial xs (replaceAt row (replaceAt column '.' (table !! row)) table)
    where (row, column) = (x `div` 9, x `mod` 9)