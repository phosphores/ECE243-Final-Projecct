#include <stdio.h>
#include <stdlib.h>

struct Player {
  int x, y;
  int height,width;
  int alive;
};

struct linePoint {
  int x, y;
  int lifespan;
};

struct platform {
    int x, y;
    int length;
};
//
const int lifeSpan = 15;
const int lineLength = 50;
const int max_x = 319;
const int max_y = 239;
const int numPlat = 5;
const int platLen = 5;
//
// struct linePoint drawnTerrain [50]={{0}};
// struct platform platforms [5] = {{0}};
//
// struct Player p1;

void start();
//
// void initialPlayer(struct Player* p);
//
// void addTerrain(int x, int y, linePoint* p, int lineLength);
// void downTickTerrain(linePoint* p, int lineLength);
// void advanceDrawnTerrain (linePoint* p, int lineLength);
// void advancePlatforms(platform* pf, int numPlat, int platLen);
//
// void advancePlayerGravity(platform* pf, int numPlat, linePoint* p, int lineLength, Player* player);
// bool collisionPlayer(platform* pf, int numPlat, linePoint* p, int lineLength, Player* player);
//
// int randomInt();

int randomInt(){
    return rand();
}

void advancePlatforms(struct platform* pf, int numPlat, int platLen){
    for (int i = 0 ; i< numPlat; i++){

        if (pf[i].x == 0){
            pf[i].x = max_x-30;
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

int collisionPlayer(struct platform* pf, int numPlat, struct linePoint* p, int lineLength, struct Player* player){
    for (int i = 0 ; i< numPlat; i++){
        if (player->x + player->width >= pf[i].x && player->x <= pf[i].x+pf[i].length){
            if (player->y+player->height==pf[i].y)
                return 1;
        }
    }
    for (int i = 0 ; i< lineLength; i++){
        if ((p[i].x >= player->x  && p[i].x <= player->x+player->width) ||(p[i].x+1 > player->x && p[i].x+1 <= player->x+player->width)){
            if (player->y+player->height==p[i].y)
                return 1;
        }
    }
    if (player->y + player->height >= 239)
      return 1;
      
    return 0;
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

void addTerrain(int x, int y, struct linePoint* p, int lineLength){
    for (int i = 0; i < lineLength; i++){
        if (p[i].x + p[i].y + p[i].lifespan == 0){
            p[i].x = x;
            p[i].y = y;
            p[i].lifespan = lifeSpan;
            return;

        }
    }
}

void advancePlayerGravity(struct platform* pf, int numPlat, struct linePoint* p, int lineLength, struct Player* player){
    if (!collisionPlayer(pf,numPlat,p,lineLength,player)&&player->y + player->height<240){
        player->y += 1;
    }
}

int main()
{
    start();
    return 0;
}
