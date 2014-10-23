//Checked an example on: http://www.instructables.com/id/Read-analog-data-directly-in-Processing/

import processing.serial.*;

Serial myPort;
String readValue;

void setup(){
  String portName = Serial.list()[0];
  myPort = new Serial (this, portName, 9600);
  size(800, 800);
  background(255, 255, 255);
  
}

void draw(){
  
  if(myPort.available() > 0){
    
    //println("Messge received from arduino...");
    
    readValue = myPort.readStringUntil('\n');
    
   // println("Read: " + readValue);
    
    if(readValue != null){
      if(readValue.contains("RFID_RED")){
         println(readValue);      
      }
      if(readValue.contains("RFID_BLUE")){
         println(readValue);      
      }
      if(readValue.contains("BLUE_PRESS")){
         println(readValue);      
      }
      if(readValue.contains("BLUE_RELEAS")){
         println(readValue);      
      }
      if(readValue.contains("RED_PRESS")){
         println(readValue);      
      }
      if(readValue.contains("RED_RELEASE")){
         println(readValue);      
      }
      
      ellipse(width/2, height/2, 50, 50);
    }
  }
}
