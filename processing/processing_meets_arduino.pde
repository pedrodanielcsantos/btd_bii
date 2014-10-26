import processing.serial.*;
import java.util.Random;

Serial myPort;
String readValue;
GameState state = GameState.START;
PlayerState blueState = PlayerState.SET;
PlayerState redState = PlayerState.SET;

//constant y coordinate of players
final int blueScreenY = 200;
final int redScreenY = 325;
//variable x coordinate of players
int blueX = 25;
int redX = 25;
//auxiliar y coordinate used to simulate jump
int blueY = 0;
int redY = 0;

//Constants used
int MAX_RAND = 225;
int MIN_RAND = 125;
int MAX_HEIGHT = -50;
int MIN_HEIGHT = 0;
int MAX_GAME_OVER_TIMER = 500;
int MAX_HURT_TIMER = 50;
int MAX_GAME_TIME = 5000;

//Timers to control several aspects of the game.
int gameTimer = 0;
int gameOverTimer = 0;
int mutexTimer = 0;
int hurdlesTimer = 0;
int blueTimer = 0;
int redTimer = 0;

PFont f;

int randomNum = 0; //used to create hurdles at a random timestamp

ArrayList<Integer> hurdles = new ArrayList<Integer>();
void setup(){
  
  f = createFont("Arial",28,true); // Arial, 16 point, anti-aliasing on
  
  //Initializing Serial Port for comunication and screen.
  String portName = Serial.list()[0];
  myPort = new Serial (this, portName, 9600);
  size(400, 400);
  background(0, 0, 0);
  
  GameState state = GameState.START;
  blueState = PlayerState.SET;
  redState = PlayerState.SET;
  
  //Initializing timers to 0 at start
  mutexTimer = 0;
  blueTimer = 0;
  redTimer = 0;
  gameOverTimer = 0;
  gameTimer = 0;
  hurdlesTimer = 0;
  
  //Initializing positions and 
  blueX = 25;
  redX = 25;
  blueY = 0;
  redY = 0;
  hurdles = new ArrayList<Integer>();
  
}
void draw(){
  
  //Check if it Game is over
  //Two conditions - Either the time has passed, or one of the players got out of the screen
  //The player who is in front wins.  
  if(gameTimer >= MAX_GAME_TIME || blueX < 0 || redX < 0){
    textFont(f,38);
    fill(255); 
    if(blueX > redX){
      text("Blue player Wins!",50,200);
    }else{
      text("Red player Wins!",50,200);
    }
   
   gameOverTimer++;
   //Check if the Game Over message can be discarted and the game can be restarted
   println("Game Over Timer: " + gameOverTimer);
   if(gameOverTimer >= MAX_GAME_OVER_TIMER){
      myPort.stop();
      setup();
   }else
     return; 
   
  }
  
  //cleans the last frame
  background(0, 0, 0);
  //variable to check if the "camera" moves
  boolean bothMoving = true;

  //makes the red lights blink
  if(state == GameState.START){
    if(mutexTimer < 50 || (mutexTimer < 100 && mutexTimer > 60)){
      stroke(#FF0000);
      fill(#FF0000);
      ellipse(200, 75, 75, 75);
    }
    
    mutexTimer++;
    
    if(mutexTimer > 110)
      state = GameState.READY;
  }
  
  //makes the green light appear
  if(state == GameState.READY || state == GameState.REDONLY || state == GameState.BLUEONLY){
    stroke(#00FF00);
    fill(#00FF00);
    ellipse(200, 75, 75, 75);
  }
  
  //IF the blue player is the only one that started running
  //OR the red player hits a hurdle and is ahead of the player
  //the camera "stops"
  if(state == GameState.BLUEONLY || (redState == PlayerState.HURTING && redX > blueX)){
    blueX++; 
    bothMoving = false;
  }
  
  //Same as the last if, but for the red player
  if(state == GameState.REDONLY || (blueState== PlayerState.HURTING && blueX > redX)){
    redX++; 
    bothMoving = false;
  }
  
  //If the red player hits a hurdle and is behind
  //the camera does not stop and he stays behind
  if(redState == PlayerState.HURTING && redX <= blueX){
    redX--;
  }
  
  //Same as last if, but for the blue player
  if(blueState == PlayerState.HURTING && blueX <= redX){
    blueX--;
  }
  
  //Camera "moves" and makes the hurdle closer
  if(bothMoving){
    for(Integer i = 0; i < hurdles.size(); i++){
      hurdles.set(i, hurdles.get(i) -1);
      gameTimer++;
    }
  }
  
  //Hurdles creation
  if(state == GameState.BOTH && bothMoving){
    
    if(hurdlesTimer >= randomNum){
      hurdles.add(400);
      hurdlesTimer = 0;
      Random rand = new Random();
      randomNum = rand.nextInt((MAX_RAND - MIN_RAND) + 1) + MIN_RAND; //Generate a random number between MIN_RAND and MAX_RAND so that the next hurdle is created at a random distance from the previous
  
    }
    hurdlesTimer++;
  }
  
  // Snippet for the communication.  
  if(myPort.available() > 0){
    
    readValue = myPort.readStringUntil('\n'); // Read line by line what's in the buffer.
    
    //Parsing the received messages    
    if(readValue != null){
      if(state == GameState.READY && readValue.contains("RFID_RED")){
         state = GameState.REDONLY;
      }
      if(state == GameState.BLUEONLY && readValue.contains("RFID_RED")){
         state = GameState.BOTH;
      }
      if(state == GameState.READY && readValue.contains("RFID_BLUE")){
         state = GameState.BLUEONLY; 
      }
      if(state == GameState.REDONLY && readValue.contains("RFID_BLUE")){
         state = GameState.BOTH;
      }
      if(readValue.contains("BLUE_PRESS")){
        println(readValue);
         blueState = PlayerState.JUMPING;
      }
      if(readValue.contains("BLUE_RELEASE")){
         println(readValue);      
      }
      if(readValue.contains("RED_PRESS") ){
        println(readValue); 
        redState = PlayerState.JUMPING;      
      }
      if(readValue.contains("RED_RELEASE")){
         println(readValue);      
      }
    }
  }
  
  drawPlayers();
  drawLines();
  drawHurdles();
  checkColisions();
  
}

//Function to check collisions between players. This checking is done by comparing if a hurdle's X position is the same as the player's X and if this is not jumping (A bit naive algorithm, does not fully check the collision)

void checkColisions(){
 for(int i = 0; i < hurdles.size(); i++){
    if(blueX == hurdles.get(i) && (blueState == PlayerState.RUNNING)){
        blueState = PlayerState.HURTING;
        blueX += 2;
    }
    
    if(redX == hurdles.get(i) && (redState == PlayerState.RUNNING)){
       redState = PlayerState.HURTING;
       redX += 2;
    }
    
 } 
  
}

//Players are being drawn here. And the jumping control is also done here. When the player jumps, it decreases its Y position (because (0,0) is on the top left of the screen) until 50 px. 
//Then, when the players reaches that altitude, starts falling again until he reaches the original position.
void drawPlayers(){
  //BluePlayer
  if(blueState == PlayerState.JUMPING && blueY >= MAX_HEIGHT){
    if(blueY == MAX_HEIGHT){
      blueState = PlayerState.FALLING;
    }else
      blueY--;
  }else if(blueState == PlayerState.FALLING  && blueY <= MIN_HEIGHT){
    if(blueY == MIN_HEIGHT){
      blueState = PlayerState.RUNNING;
     }else
       blueY++; 
  }
  if(blueState == PlayerState.HURTING){
    if(blueTimer < MAX_HURT_TIMER){
     blueTimer++; 
    }else{
      blueState = PlayerState.RUNNING;
      blueTimer = 0;
    }
  }
    
  //RedPlayer
  if(redState == PlayerState.JUMPING && redY >= MAX_HEIGHT){
    if(redY == MAX_HEIGHT){
      redState = PlayerState.FALLING;
     }else
      redY--;
  }else if(redState == PlayerState.FALLING  && redY <= MIN_HEIGHT){
    if(redY == MIN_HEIGHT){
      redState = PlayerState.RUNNING;
     }else
       redY++;
  } 
  
  if(redState == PlayerState.HURTING){
    if(redTimer < MAX_HURT_TIMER){
     redTimer++; 
    }else{
      redState = PlayerState.RUNNING;
      redTimer = 0;
    }
  }
  
  stroke(#0000FF);
  fill(#0000FF);
  ellipse(blueX,blueScreenY + blueY, 40, 40);
  
  //RedPlayer
  stroke(#FF0000);
  fill(#FF0000);
  ellipse(redX,redScreenY + redY, 40, 40);
}
void drawLines(){
  stroke(#FFFFFF);
  line(0,175,400,175);
  line(0,225,400,225);
  line(0,300,400,300);
  line(0,350,400,350);
}
void drawHurdles(){
  stroke(#FFFFFF);
  for(Integer i: hurdles){
    line(i, 185, i + 25, 200);
    line(i, 185, i, 200);
    line(i + 25, 200, i + 25, 215);
    line(i, 200, i + 2, 198);
    line(i + 25, 215, i + 27, 213);
    
    line(i, 310, i + 25, 325);
    line(i, 310, i, 325);
    line(i + 25, 325, i + 25, 340);
    line(i, 325, i + 2, 323);
    line(i + 25, 340, i + 27, 338);
  }
}
