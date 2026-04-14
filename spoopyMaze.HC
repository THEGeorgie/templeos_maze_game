$SP,"<1>",BI=1$



$SP,"<2>",BI=2$






#define TILE_SIZE 24

#define GRID_W    64
#define GRID_H    48

#define MAZE_W ((GRID_W - 1) / 2)
#define MAZE_H ((GRID_H - 1) / 2)

#define CELL_EMPTY 0
#define CELL_WALL  1
#define CELL_EXIT  2

#define exit_x 0
#define exit_y 0


class Collider{
    I64 x,y;
    I64 w,h;
};
class Keys{
	Bool left,right,up,down;
};
class Player{
    Collider collider_box;
};
class Cell{
    I64 c_type
};
class MazeState{
    I64 cells[MAZE_W];
    I64 nex_set_id;
};

Cell grid[GRID_W][GRID_H];

U0 Populate(MazeState *state){
    I64 i;
    for(i = 0; i < GRID_W; i++){
        if(state->cells[i] == 0){
            state->cells[i] = ++(state->nex_set_id);
        }
    }
}


Bool Same(MazeState *state, I64 c1, I64 c2){
    return state->cells[c1] == state->cells[c2];
}

U0 Merge(MazeState *state, I64 sink_cell, I64 target_cell, I64 row_y){
    I64 sink_id = state->cells[sink_cell];
    I64 target_id = state->cells[target_cell];

    if(sink_id == target_id){
        return;
    }

    I64 i;
    for(i = 0; i < MAZE_W; i++){
        if(state->cells[i] == target_id){
            state->cells[i] = sink_id;
        }
    }

    grid[row_y * 2 + 2][sink_cell * 2 + 1].c_type = CELL_EMPTY;
}

U0 Process_maze_row(MazeState *state,I64 row_y, Bool finish){
    
    I64 c, i, j;
    for(c = 0; c < MAZE_W -1; c++){

        grid[row_y * 2 + 1][c * 2 + 1].c_type = CELL_EMPTY;

        if(!Same(state, c, c+1) && (finish || RandU16() % 2 == 0)){
            Merge(state, c, c +1, row_y);
        }
    }

    if(finish){
        for (i = 0; i < MAZE_W -1; i++){
            if(!Same(state, i,i+1)){
                Merge(state,i,i+1,row_y);
            }
        }

        return;
    }

    I64 next_row[MAZE_W];
    MemSet(next_row, 0, sizeof(I64) * MAZE_W);

    for(i = 0; i < MAZE_W; i++){
        I64 current_id = state->cells[i];

        Bool already_done = FALSE;
        for(j = 0; j < MAZE_W; j++){
            if(state->cells[j] == current_id && next_row[j] != 0){
                already_done = TRUE;
                break;
            }
        }

        if(already_done) goto skip_pos;
        

        I64 memebers[MAZE_W], count = 0;
        for(j = 0; j < MAZE_W; j++){
            if(state->cells[j] == current_id){
                memebers[count++] = j;
            }
        }
        

        I64 num_drops = Max(1, (RandU16() % count) +1);
        for (j = 0; j < num_drops; j++) {
            I64 idx = memebers[RandU16() % count];
            next_row[idx] = current_id;
            grid[idx * 2 + 1][row_y * 2 + 2].c_type = CELL_EMPTY;
        }
        skip_pos:
    }
    
    for(i = 0; i < MAZE_W; i++){
        if(next_row[i] == 0){
            state->cells[i] = 0;
        }else{
            state->cells[i] = next_row[i];
        }
    }
}


U0 GenerateMaze() {
  MazeState state;
  I64 y;

  MemSet(&state, 0, sizeof(MazeState));

  for (y = 0; y < MAZE_H; y++) {
    Populate(&state);

    Bool is_last = (y == (MAZE_H - 1));
    
    Process_maze_row(&state, y, is_last);
  }
}





Bool TileSolid(I64 tx, I64 ty)
{
    if (tx < 0 || ty < 0 || tx >= GRID_W || ty >= GRID_H)
        
        return TRUE; // clamp to solid so no invalid access

    return grid[tx][ty].c_type == CELL_WALL;
}


Bool Collider_vs_Tile(Collider *b, I64 tx, I64 ty)
{
    F64 tx0 = tx*TILE_SIZE;
    F64 ty0 = ty*TILE_SIZE;

    return !(b->x + b->w <= tx0 ||
             b->x >= tx0 + TILE_SIZE ||
             b->y + b->h <= ty0 ||
             b->y >= ty0 + TILE_SIZE);
}

U0 MoveColider(Collider *b, F64 dx, F64 dy)
{
    // --------------------
    // Move X axis
    // --------------------
    
    if (dx != 0) {
        b->x += dx;

        I64 left_x   = b->x / TILE_SIZE;
        I64 right_x  = (b->x + b->w - 1) / TILE_SIZE;
        I64 top_x    = b->y / TILE_SIZE;
        I64 bottom_x = (b->y + b->h - 1) / TILE_SIZE;
        I64 ty_x;
        for (ty_x= top_x; ty_x <= bottom_x; ty_x++){
            I64 tx_x;
            for (tx_x= left_x; tx_x <= right_x; tx_x++)
            {
                
                if (TileSolid(tx_x, ty_x)) {
                    // Resolve
                    if (dx > 0)
                        b->x = tx_x*TILE_SIZE - b->w;
                    else
                        b->x = (tx_x+1)*TILE_SIZE;
                }
                
            }
        }
        
        
    }
    
    
    // --------------------
    // Move Y axis
    // --------------------
    
    if (dy != 0) {
        b->y += dy;

        I64 left_y   = b->x / TILE_SIZE;
        I64 right_y   = (b->x + b->w - 1) / TILE_SIZE;
        I64 top_y     = b->y / TILE_SIZE;
        I64 bottom_y  = (b->y + b->h - 1) / TILE_SIZE;
        
        Bool hit = FALSE;
        top_y    = Clamp(top_y, 0, GRID_H - 1);
        bottom_y = Clamp(bottom_y, 0, GRID_H - 1);

        I64 ty_y;
        for (ty_y= top_y; ty_y <= bottom_y; ty_y++) {
            I64 tx_y;
            for (tx_y= left_y; tx_y <= right_y; tx_y++) {
                if (TileSolid(tx_y, ty_y)) {
                    if (dy > 0)
                        b->y = ty_y * TILE_SIZE - b->h;
                    else
                        b->y = (ty_y + 1) * TILE_SIZE;

                    hit = TRUE;
                    break;
                }
                
            }
         
        }
        
        
        
        
    }

}


Keys keys;
Player player;


U0 InitGrid(){
    //Vstima vse celice v polno
    I64 x, y;
    for(y = 0; y < GRID_H; y++){
        for(x = 0; x < GRID_W; x++){
            grid[x][y].c_type = CELL_WALL;
        }
    }

    for(y = 0; x < GRID_H; y+=2){
        for(x = 0; x < GRID_W; x+=2){
            grid[x][y].c_type = CELL_EMPTY;
        }
    }
    
    
}

U0 Init()
{   
    QueInit(&keys);
	QueInit(&player);
	player.collider_box.x = 5*TILE_SIZE;
	player.collider_box.y = 5*TILE_SIZE;
	player.collider_box.w = TILE_SIZE;
	player.collider_box.h = TILE_SIZE;

	keys.left = FALSE;
	keys.right = FALSE;
	keys.down = FALSE;
	keys.up = FALSE;
    
    InitGrid();
    GenerateMaze();

}

U0 CleanUp()
{
    DocClear;
}

U0 HandleInput(){
	if(keys.left == TRUE){
		MoveColider(&player.collider_box, -4, 0);
	}
	if(keys.right == TRUE){
		MoveColider(&player.collider_box, 4, 0);
	}
	if(keys.up == TRUE){
		MoveColider(&player.collider_box, 0, -4);
	}
	if(keys.down == TRUE){
		MoveColider(&player.collider_box, 0, 4);
	}

    I64 p_tx = (player.collider_box.x + player.collider_box.w / 2) / TILE_SIZE;
    I64 p_ty = (player.collider_box.y + player.collider_box.h / 2) / TILE_SIZE;
    
    if (p_ty == 19 && !TileSolid(p_tx, p_ty)) {
        Init;
    }
}

U0 DrawIt(CTask *task, CDC *dc)
{
  HandleInput;

  I64 p_tx = player.collider_box.x / TILE_SIZE;
  I64 p_ty = player.collider_box.y / TILE_SIZE;
  I64 view_dist = 3; 

  I64 x, y;
  for (y = 0; y < GRID_H; y++) {
    for (x = 0; x < GRID_W; x++) {
      
      // 1. Check if the tile is within the visibility radius
      if (AbsI64(x - p_tx) <= view_dist && AbsI64(y - p_ty) <= view_dist) {
        
        if (TileSolid(x, y)) {
          // WALLS: Draw the wall sprite (usually black/dark in your BI=2)
          Sprite3B(dc, x * TILE_SIZE, y * TILE_SIZE, 0, $IB,"<2>",BI=2$);
        } else {
          // PATH: Draw a solid WHITE rectangle for the floor
          dc->color = WHITE;
          GrRect(dc, x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        }

      } else {
        // FOG: Draw LIGHTGRAY for everything outside the 3-block radius
        dc->color = LTGRAY;
        GrRect(dc, x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
      }
    }
  }

  // Draw Player on top
  Sprite3B(dc, player.collider_box.x, player.collider_box.y, 0, $IB,"<1>",BI=1$);
}


U0 Main(){
  CDC *dc = DCAlias;
  I64 ch, sc;
  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;

  Init;
  Fs->draw_it=&DrawIt;
  
  try {
    while (TRUE){
        

		switch(GetMsg(&ch,&sc,1<<MSG_KEY_DOWN+1<<MSG_KEY_UP)){
			case MSG_KEY_DOWN:
				switch(ch){
					case 0:
                        //Print("Player cords x:%d,y:%d",player.collider_box.x, player.collider_box.y);
	  					switch (sc.u8[0]) {
	    					case SC_CURSOR_LEFT:
								keys.left = TRUE;
	      					break;
	    					case SC_CURSOR_RIGHT:
								keys.right = TRUE;
	      					break;
	    					case SC_CURSOR_UP:
								keys.up = TRUE;
	      					break;
	    					case SC_CURSOR_DOWN:
								keys.down = TRUE;
	      					break;
	 					}
	  				break;
					case '\n':
	  					CleanUp;
	  					Init;
	  				break;
					case CH_SHIFT_ESC:
					case CH_ESC:
	  					goto mg_done;
				}
			break;
			case MSG_KEY_UP:
				switch(ch){
					case 0:
						switch(sc.u8[0]){
							case SC_CURSOR_LEFT:
								keys.left = FALSE;
	      					break;
	    					case SC_CURSOR_RIGHT:
								keys.right = FALSE;
	      					break;
	    					case SC_CURSOR_UP:
								keys.up = FALSE;
	      					break;
	    					case SC_CURSOR_DOWN:
								keys.down = FALSE;
	      					break;
						}
					break;
				}
			break;
			
		}
  	}
    mg_done:
  }
    catch{
		PutExcept;
		SettingsPop;
		CleanUp;
		MenuPop;
    }   
}
 
Main;        2                   																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									       																									               2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    