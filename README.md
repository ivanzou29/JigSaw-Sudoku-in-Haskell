# JigSaw-Sudoku-in-Haskell
## To run the sudoku program:

### Preparation
1. Have some txt files shown on HKU Moodle to load the map if you wish
2. Have package "System.Random" installed in ghc or stack for compilation, as Random will be used in generating the board.

### Compilation
1. If you are using stack ghci, use "stack ghc JigsawSudoku.hs" to compile the file.
2. If you are using ghc, use "ghc -o JigsawSudoku JigsawSudoku.hs" to compile the file

### Running
Use command "./JigsawSudoku" to play the game by following the displayed instruction.

### Detailed Report

#### 1.	Building Procedure
Before building the project, please read the file “readme.txt” included in the submission. To prepare for the build, make sure your “ghc” or “stack ghci” functions normally. You will also need the package “System.Random”. Please download that package online at: https://hackage.haskell.org/package/random. If you are using “stack”, you could directly run “stack install random” to install it. Then, please use the following command to build the project:
	“ghc -o JigsawSudoku JigsawSudoku.hs” or
	“stack ghc JigsawSudoku.hs”

Then, please use the following command to run the project:
	“./JigsawSudoku”

#### 2.	Basic Functionality
This section only lists basic functionality. For extra features, please refer to section 5.

#### 2.1.Start the game
You may start the game by running the “./JigsawSudoku” command and you will get the following prompt:
 
#### 2.2.Load a map
You can press “1” for loading a map. Then, you could enter the name of the “.txt” file storing the information of the sudoku map. After loading, you will get your board displayed.
 

The program will then display the following prompt for you to choose the actions:
 

#### 2.3.Make a move
You could enter “1” for making a move and then provide the row, column and the number to fill in the cell:
 

#### 2.4.Save a board
You can enter “2” to save the current board. It will be saved to the save file from which you load the map:
 
Then you are able to continue playing the game with your progress saved.

#### 2.5.Error handling for the move action
When you tries to make an invalid move, the system would stop this and tells you to enter another option.
 

#### 2.6.Check ending
The system is able to tell you the result of your game once all the cells are filled. For a valid ending, you win the game.
 


For an invalid board, you would lose the game:
 

#### 3.	Choice of data structures
The choice of data structure is relatively simple for representing the board. The program could split the input file into two lists of strings, with each of length 9. 
  

The first list(“blockInfoList”) contains the first 9 lines of the input file specifying the block information (which cell belongs to which block, and what the block number is). The second list(“filledNumInfoList”) contains the next 9 lines of the input file specifying the filled numbers in the cells. 

Basically, I have not used a newly defined data structure to store the board. Instead, I just used 2 list of strings. The reason behind this is that sometimes I may not need to pass both lists as arguments of some functions. Sometimes, I just need to get the block number from the block information list. Sometimes, I might need to update the filled board by passing only the filled number information list as an argument. Thus, storing the two lists separately could make the program’s stack frame lighter when making function calls.
 
#### 4.	Error cases and ending
Error moves would be prevented by the system, as shown in last section. The system would check whether a move is valid or not by calling the following function.
 
For ending, the system would check whether all cells are filled. But an ending does not necessarily mean a victory. The system would also check whether the ending is valid or not, and provide corresponding information to the user (whether the user won the game or lost the game).
 
Check ending function
 
Check win function

#### 5.	Additional features
In summary, the following additional features have been implemented: Undo/Redo, Hint, Solver and Generate board.

#### 5.1.Undo and Redo
The program has stored a list of previous states, a list of filled number information lists containing all the previous boards that the user has covered before.

At the same time, the program stores the succeeding boards information for “redo”s when the user has done some “undo”s. Thus, the undo and redo functions are realised and could be used by entering the prompted command numbers.
 

A demo of how to make the undo operation is as follows:
 
A demo of how to make the redo operation is:
 
#### 5.2.Hint
The program provides hint for the user when the hint prompt “number 4” is entered by the user. The hint function would find the next empty cell on the board and randomly return one of all the possible choices that do not violate the rule of the sudoku game.
 
If no hints available for next empty cell, the program will ask the user to undo some steps to seek for other choices.
 
#### 5.3.Solver
The system could solve the sudoku when the user gives “S” command for a direct solution. It uses backtracking to explore all possibilities of the next empty cell. The concept is, the algorithm will dig along one way until it finds no options for the next step. If that happens, the algorithm turns back to the previous node and goes to other options of that node. This recursive function could finally lead to one solution if it exists. Basically, it is similar to a DFS(depth first search) approach. Therefore, it terminates as soon as it finds the solution. Even though a naïve way(which is to explore the next empty cell one by one, without looking at whether other cells still have valid choices) is adopted, it saves a lot of time in computing which the next empty cell to go for is. Therefore, it could be computationally cheaper. For the default map given on moodle, it takes around 3 seconds to find a solution.
 
#### 5.4.Generate board
A random board could be generated by prompt “2” at the beginning of the game to generate a board. The new board is generated among several choices of the block distributions. The system then tries to solve the empty board for a solution. Then a function will generate random numbers standing for a series of coordinates. Those coordinates on the solution board would be made empty, and passed to the user end for the user to complete the game. The user will enter a name for the board, which would be used for saving the board information as a “.txt” file later.
 
Due to the large computational costs in solving an empty board and hide some coordinates, the board generating process will cost 1 to 2 minutes. As the system would solve it before providing the partial board to the user, the board will definitely have a valid solution.

#### 6.	Improvements to make
This Jigsaw Sudoku game still has some spaces for improvement. It could be better if it has a good-looking GUI so that it would be more user friendly. Apart from that, I believe better algorithms could be found to solve the sudoku faster, which could make the board generating process faster as well. 
