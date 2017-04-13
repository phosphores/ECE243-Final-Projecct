#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

struct Player {
  int x, y;
  int height,width;
  int alive;
};

struct linePoint{
  int x, y;
  int lifespan;
};

struct platform{
    int x, y;
    int length;
};

const int lifeSpan = 5;
const int lineLength = 50;
const int max_x = 319;
const int max_y = 239;
const int numPlat = 5;
const int platLen = 5;

struct linePoint drawnTerrain [50]={{0}};
struct platform platforms [5] = {{0}};

struct Player p1;

void downTickTerrain(struct linePoint* p, int lineLength);
void addTerrain(int x, int y,struct linePoint* p, int lineLength);
void initialPlayer(struct Player* p);
void advancePlatforms(struct platform* pf, int numPlat, int platLen);
void advanceDrawnTerrain (struct linePoint* p, int lineLength);
bool collisionPlayer(struct platform* pf, int numPlat,struct linePoint* p, int lineLength,struct Player* player);
void advancePlayerGravity(struct Player* p);
void movePlayer(struct Player* p, char c);
int randomInt();


int main()
{
    
    
    printf("Hello, World!\n");
    for (int i = 0; i < lineLength; i++){
        drawnTerrain[i].x = rand()%max_x;
        drawnTerrain[i].y = rand()%max_y;
        drawnTerrain[i].lifespan = rand()%lifeSpan;
        printf("(x,y) is (%d,%d) with hp %d\n", (drawnTerrain[i].x),(drawnTerrain[i].y),(drawnTerrain[i].lifespan));
    }
    initialPlayer(&p1);
    /*
    for (int i =0; i < 3; i++){
        
        downTickTerrain(drawnTerrain,lineLength);
         printf ("Tickdown %d\n",i);
        for (int i = 0; i < lineLength; i++){
      
        printf("(x,y) is (%d,%d) with hp %d\n", (drawnTerrain[i].x),(drawnTerrain[i].y),(drawnTerrain[i].lifespan));
        }
    }
    */
    if(collisionPlayer(platforms, numPlat,drawnTerrain,lineLength,&p1))
        printf("collide");
   
   
    return 0;
}

void initialPlayer(struct Player* p){
    p->x =213;
    p->y =130-30; 
    p->height = 30; 
    p->width = 15; 
    p->alive = 1;
}
void advancePlatforms(struct platform* pf, int numPlat, int platLen){
    for (int i = 0 ; i< numPlat; i++){
        
        if (pf[i].x == 0){
                pf[i].x = max_x;
                pf[i].y = randomInt()%max_y;
                pf[i].length = platLen;
            
        }

        else
            pf[i].x -= 1;
            
    }
}
void advanceDrawnTerrain (struct linePoint* p, int lineLength){
    for (int i = 0 ; i< lineLength; i++){
        
        if (p[i].x > 0){
            p[i].x -= 1;
        }
        else{

            p[i].lifespan =0;
            p[i].x = 0;
            p[i].y = 0;
        }
    }
}

bool collisionPlayer(struct platform* pf, int numPlat,struct linePoint* p, int lineLength,struct Player* player){
    for (int i = 0 ; i< numPlat; i++){
        if (player->x + player->width >= pf[i].x && player->x <= pf[i].x+pf[i].length){
            if (player->y+player->height==pf[i].y)
                return true;
        }
    }
    for (int i = 0 ; i< lineLength; i++){
        if ((p[i].x >= player->x  && p[i].x <= player->x+player->width) ||(p[i].x+1 > player->x && p[i].x+1 <= player->x+player->width)){
            if (player->y+player->height==p[i].y)
                return true;
        }
    }
    return false;
}


void downTickTerrain(struct linePoint* p, int lineLength){
    
    for (int i  =0 ; i < lineLength; i++){
        if (p[i].lifespan > 0){
          if (p[i].x <0||p[i].y < 0){
            p[i].lifespan = 0;
            p[i].x = 0;
            p[i].y=0;
          }
          else
            p[i].lifespan--;
        }
       
        else{
            p[i].lifespan = 0;
            p[i].x = 0;
            p[i].y=0;
        }
            
    }
}

void addTerrain(int x, int y,struct linePoint* p, int lineLength){
    for (int i = 0; i < lineLength; i++){
        if (p[i].x + p[i].y + p[i].lifespan == 0){
            p[i].x = x;
            p[i].y = y;
            p[i].lifespan = lifeSpan;
            return;

        }
    }
}


void advancePlayerGravity(struct platform* pf, int numPlat,struct linePoint* p, int lineLength,struct Player* player){
    if (!collisionPlayer(pf,numPlat,p,lineLength,player)){
        player->y -= 1;
    }
}
int randomInt(){
    return rand();
}
void movePlayer(struct Player* p, char c){
    
}