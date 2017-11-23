/*
 * bfs.h
 *
 *  Created on: Oct 30, 2017
 *      Author: kenda
 */

#ifndef BFS_H_
#define BFS_H_
#define MAZE_WIDTH (5)
#define ELEMENT_COUNT (MAZE_WIDTH*MAZE_WIDTH)

#define RANK(row, col) ((row)*MAZE_WIDTH+(col))
#define ROW(rank) ((rank)/MAZE_WIDTH)
#define COL(rank) ((rank)%MAZE_WIDTH)
#define NUM_NEIGHBORS 4
#define NEG_ONE -1
#define NEG_TWO -2
#define ZERO 0
#define ONE 1
#define TWO 2
#define THREE 3
#define LAST_ROW 9

#define TURN_LEFT 3
#define TURN_RIGHT 2
#define GO_FORWARD 1



//void push_back(list_t* list, int rank);
void find_shortest_path(int start_rank, int goal_rank, const int obstacles[], int AStarFlag,int ManhattanDistFlag, int command_holder[]);
void find_path_AStar(int start_rank, int goal_rank, const int obstacles[], int AStarFlag, int ManhattanDistFlag);

int test_main();
//void push_back(list_t* list, int rank);

#endif /* BFS_H_ */
