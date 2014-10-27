#include <SoftwareSerial.h>


//Initialization of global variables and constants
SoftwareSerial RFID(2, 3); // RX and TX

int data1 = 0;
int readTag = -1;
int BLUE = 10;
int RED = 11;

int buttonPressed = 0;
int buttonUnpressed = 1;
int redButtonState = buttonUnpressed;
int blueButtonState = buttonUnpressed;

int bluePlayerButton = 7;
int redPlayerButton = 8;

int redTag[14] = {2,51,68,48,48,65,57,49,56,52,69,67,50,3}; //Identifier of the red RFID tag
int blueTag[14] = {2,48,51,48,48,65,53,50,49,52,52,67,51,3}; // Identifier of the blue RFID tag
int newtag[14] = { 0,0,0,0,0,0,0,0,0,0,0,0,0,0}; // used for read comparisons


void setup()
{
  RFID.begin(9600); // start serial to RFID reader
  Serial.begin(9600); // start serial to PC 
  
  //Button setup
  pinMode(bluePlayerButton,INPUT);
  digitalWrite(bluePlayerButton,HIGH);
  pinMode(redPlayerButton,INPUT);
  digitalWrite(redPlayerButton,HIGH);
}

//Comparing two tags (arrays of values)
boolean comparetag(int aa[14], int bb[14])
{
  boolean ff = false;
  int fg = 0;
  for (int cc = 0 ; cc < 14 ; cc++){
    if (aa[cc] == bb[cc]){
      fg++;
    }
  }
  if (fg == 14){
    ff = true;
  }
  return ff;
}

//Check if a read tag is one of ours and return its value.
void checkmytags(){
  
  if (comparetag(newtag, redTag) == true){
    readTag = RED;
  }
  if (comparetag(newtag, blueTag) == true){
    readTag = BLUE;
  }
}

//Function to read RFID tags from the sensor
void readTags()
{
  readTag = -1;
  if (RFID.available() > 0) {//checks if there is any value to read on the buffer.
    // read tag numbers
    delay(100); // needed to allow time for the data to come in from the serial buffer.
    for (int z = 0 ; z < 14 ; z++){ // read the rest of the tag
      data1 = RFID.read();
      newtag[z] = data1;
    }
    RFID.flush(); // stops multiple reads
    // Compare the read value to check if it is a valid one
    checkmytags();
  }
  // Based on the read value, write to the buffer the correspondent command
  if (readTag == BLUE){ // if we had a match{
    Serial.println("RFID_BLUE");    
  }else if (readTag == RED){ // if we didn't have a match
    Serial.println("RFID_RED");
  }
  readTag = -1;
}

//Read the value of the buttons - if it is the red or the blue one or even if it is a press or a release from that button.
void readButtons(){
  
  if(digitalRead(bluePlayerButton) == buttonPressed){
    if(blueButtonState == buttonUnpressed){
      blueButtonState = buttonPressed;
      Serial.println("BLUE_PRESS");
    }
  }else{
    if(blueButtonState == buttonPressed){
      blueButtonState = buttonUnpressed;
      Serial.println("BLUE_RELEASE");
    }
  }
  
  if(digitalRead(redPlayerButton) == buttonPressed){
    if(redButtonState == buttonUnpressed){
      redButtonState = buttonPressed;
      Serial.println("RED_PRESS");
    }
  }else if (digitalRead(redPlayerButton) == buttonUnpressed){
    if(redButtonState == buttonPressed){
      redButtonState = buttonUnpressed;
      Serial.println("RED_RELEASE");
    }
  }
}

//In the main loop, we are reading the buttons and RFID tags to send commands to processing to notify it from the user's actions, and then these commands are parsed on processing
//
void loop()
{
  readTags();
  readButtons();
}
