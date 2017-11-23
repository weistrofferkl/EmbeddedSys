/*
 * bfs.h
 *
 *  Created on: Oct 30, 2017
 *      Author: kenda
 */

#ifndef BFS_H_
#define BFS_H_
#define MAZE_WIDTH (10)
#define ELEMENT_COUNT (MAZE_WIDTH*MAZE_WIDTH)

#define RANK(row, col) ((row)*MAZE_WIDTH+(col))
#define ROW(rank) ((rank)/MAZE_WIDTH)
#define COL(rank) ((rank)%MAZE_WIDTH)

//void push_back(list_t* list, int rank);
int test_main();
//void push_back(list_t* list, int rank);

#endif /* BFS_H_ */
