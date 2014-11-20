import fisica.*;
import kinect4WinSDK.*;

final int HEIGHT = 720;
final int WIDTH = 960;
int ballCount = 0;
int lastTouch = 0;

Kinect kinect;
ArrayList <SkeletonData> bodies;
HashMap <Integer, FBox> racquets;
HashMap <Integer, Integer> result;
HashMap <Integer, Integer> best;
HashMap <Integer, FCircle> balls;

FBody net;

PFont f;

GameState state;

FWorld world;

int RED_X = 100;
int BLUE_X = 500;
int MENU_Y = 10;
int MENU_WIDTH = 300;
int MENU_HEIGHT = 150;

void setup()
{
  size(WIDTH, HEIGHT);
  smooth();

  state = GameState.INITIAL_MENU;

  kinect = new Kinect(this);
  bodies = new ArrayList<SkeletonData>();

  racquets = new HashMap<Integer, FBox>();
  Fisica.init(this);
  world = new FWorld();

  result = new HashMap<Integer, Integer>();
  best = new HashMap<Integer, Integer>();
  balls = new HashMap<Integer, FCircle>();
  net = new FBox(10, 360);
  net.setPosition(width/2, height - 180);
  net.setStatic(true);
  net.setFill(0);
  net.setRestitution(0);

  f = createFont("Arial", 26, true);

  world.setGravity(0, 500);
}

void draw()
{
  background(255, 255, 255);
  try {
    image(kinect.GetImage(), 0, 0, WIDTH, HEIGHT);
  } 
  catch (Exception e) {
    println("No Kinect");
  }
  drawResults();
  try {
    synchronized(world) {
      world.draw();
      world.step();
    }
  } 
  catch (Exception e) {
    println("No world");
  }
  checkTheBalls();
  synchronized(bodies) {
    for (int i=0; i<bodies.size (); i++) 
    {
      drawSkeleton(bodies.get(i));
    }
  }
  if (state == GameState.INITIAL_MENU) {
    checkAndInside();
    drawMenu();
  }
}

//LEFT PLAYER IS ALWAYS INDEX 0;
//RIGHT PLAYER IS ALWAYS INDEX 1;
void checkTheBalls() {

  ArrayList<Integer> toRemove = new ArrayList<Integer>();
  HashMap<Integer, FCircle> toAdd = new HashMap<Integer, FCircle>();

  synchronized(balls) {
    for (Integer id : balls.keySet ()/*FCircle ball : balls*/) {

      if (balls.get(id).getX() < 0 || balls.get(id).getX() > width || balls.get(id).getY() > height) { 
        //println("Ball fell...");   

        if (state == GameState.ONEVSONE) {
          //println("One vs one");
          FCircle ball = new FCircle(25);
          if (balls.get(id).getY() > height) {
            //println("Ball out of bound vertically");
            if (balls.get(id).getX() < (width/2)) {//Point for right player
              //println("Point for right Player");
              ball.setPosition(width/4, 0);
              synchronized(result) {
                synchronized(bodies) {
                  result.put(bodies.get(1).dwTrackingID, result.get(bodies.get(1).dwTrackingID) + 1);
                }
              }
            } else { // Point for left player
              //println("Point for left player");
              ball.setPosition((width/4)*3, 0);
              synchronized(result) {
                synchronized(bodies) {
                  result.put(bodies.get(0).dwTrackingID, result.get(bodies.get(0).dwTrackingID) + 1);
                }
              }
            }
            //println("gonna update balls now");
            synchronized(world) {
              world.remove(balls.get(id));
              balls.remove(id);
              ball.setRestitution(0.75);
              ball.setFill(255, 102, 0);
              world.add(ball);
              balls.put(0, ball);
            }
          } else {
            //println("Ball out");
            if (lastTouch == 0) {
              ball.setPosition(width/4, 0);
              synchronized(result) {
                synchronized(bodies) {
                  result.put(bodies.get(1).dwTrackingID, result.get(bodies.get(1).dwTrackingID) + 1);
                }
              }
            } else {
              ball.setPosition((width/4)*3, 0);
              synchronized(result) {
                synchronized(bodies) {
                  result.put(bodies.get(0).dwTrackingID, result.get(bodies.get(0).dwTrackingID) + 1);
                }
              }
            }

            synchronized(world) {
              world.remove(balls.get(id));
              balls.remove(id);
              ball.setRestitution(0.75);
              ball.setFill(255, 102, 0);
              world.add(ball);
              balls.put(0, ball);
            }
          }

          return;
        }

        synchronized(world) {
          world.remove(balls.get(id));
        }

        synchronized(result) {
          if (result.containsKey(id)) {
            result.put(id, 0);

            FCircle ball = new FCircle(25);
            synchronized(bodies) {
              for (int i = 0; i < bodies.size (); i++) {
                if (bodies.get(i).dwTrackingID == id) {
                  ball.setPosition(bodies.get(i).position.x*width/*random(0+10, width-10)*/, 0);
                }
              }
            }

            ball.setRestitution(0.75);
            ball.setFill(255, 102, 0);

            synchronized(world) {
              world.add(ball);
            }

            toAdd.put(id, ball);
          } else {
            toRemove.add(id);
            ballCount--;
          }
        }
      }
    }

    for (Integer i : toRemove) {
      balls.remove(i);
    }

    balls.putAll(toAdd);
  }
}

void drawResults() {
  synchronized(bodies) {
    for (SkeletonData _s : bodies) {
      synchronized(result) {
        textFont(f, 26);
        fill(0, 0, 255);
        text(result.get(_s.dwTrackingID), _s.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HEAD].x*width, _s.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HEAD].y*height-50);
      }
      synchronized(best) {
        textFont(f, 26);
        fill(255, 0, 0);
        text(best.get(_s.dwTrackingID), _s.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HEAD].x*width, _s.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HEAD].y*height-75);
      }
    }
  } 
  if (state == GameState.ONEVSONE) {
    fill(0, 255, 0);
    line(width/2, 0, width/2, height);
  }
}

boolean isInsideOneVsOne(float x, float y) {
  if ( x > RED_X && x < (RED_X + MENU_WIDTH) && y > MENU_Y && y < (MENU_Y + MENU_HEIGHT))
    return true; 
  else
    return false;
}

boolean isInsideAllAround(float x, float y) {
  if ( x > BLUE_X && x < (BLUE_X + MENU_WIDTH) && y > MENU_Y && y < (MENU_Y + MENU_HEIGHT))
    return true; 
  else
    return false;
}
void checkAndInside() {
  synchronized(bodies) {
    for (int i = 0; i < bodies.size (); i++) {
      float x = bodies.get(i).skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].x*width;
      float y = bodies.get(i).skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].y*height;

      if (isInsideOneVsOne(x, y)) {
        state = GameState.ONEVSONE;
        if (bodies.size() == 2) {
          startOneVsOne();
        }
        println("State changed to onevs one");
      }
      if (isInsideAllAround(x, y)) {
        state = GameState.ALLAROUND;
        startAllAround();
        println("State changed to allaround");
      }
    }
  }
}
void startOneVsOne() {
  synchronized(world) {
    FCircle ball = new FCircle(25);
    ball.setPosition(random(0+10, width-10), 0);
    ball.setRestitution(0.75);
    ball.setFill(255, 102, 0);
    world.add(ball);
    balls.put(0, ball);
    ballCount++;

    world.add(net);
  }
}

void startAllAround() {
  synchronized(bodies) {
    for (int i = 0; i < bodies.size (); i++) {
      FCircle ball = new FCircle(25);
      ball.setPosition(bodies.get(i).position.x*width/*random(0+10, width-10)*/, 0);
      ball.setRestitution(0.75);
      ball.setFill(255, 102, 0);

      synchronized(world) {
        world.add(ball);
      }

      synchronized(balls) {
        balls.put(bodies.get(i).dwTrackingID, ball);
      }
      ballCount++;

      synchronized(result) {
        result.put(bodies.get(i).dwTrackingID, 0);
      }

      synchronized(best) {
        best.put(bodies.get(i).dwTrackingID, 0);
      }
    }
  }
}

void drawMenu() {
  fill(255, 0, 0);
  rect(RED_X, MENU_Y, MENU_WIDTH, MENU_HEIGHT);

  textFont(f, 26);                
  fill(255);                      
  text("One vs One", 175, 100);

  fill(0, 0, 255);
  rect(BLUE_X, MENU_Y, MENU_WIDTH, MENU_HEIGHT);

  textFont(f, 26);                 
  fill(255);                       
  text("All Around", 575, 100);

  textFont(f, 26);
  fill(255);
  text("With your right hand, pick a game mode!", 400, 200);
}

void appearEvent(SkeletonData _s) 
{
  if (_s.trackingState == Kinect.NUI_SKELETON_NOT_TRACKED) 
  {
    return;
  }
  synchronized(bodies) {
    bodies.add(_s);
    //println("A body appeard. Id is " + _s.dwTrackingID + ". The number of bodies is " + bodies.size());
    synchronized(world) {
      synchronized(racquets) {
        FBox _r = new FBox(200, 50);
        _r.setPosition(_s.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].x*width, _s.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].y*height);
        _r.setStatic(true);
        _r.setFill(0);
        _r.setRestitution(0);
        world.add(_r);
        racquets.put(_s.dwTrackingID, _r);
      }
      if ((state == GameState.ONEVSONE && balls.size() == 0  && bodies.size() == 2) || state == GameState.ALLAROUND) {  
        println("Adding ball to game...");
        FCircle ball = new FCircle(25);
        ball.setPosition(_s.position.x*width/*random(0+10, width-10)*/, 0);
        ball.setRestitution(0.75);
        ball.setFill(255, 102, 0);
        world.add(ball);

        synchronized(balls) {
          balls.put(_s.dwTrackingID, ball);
        }

        ballCount++;
      }
      synchronized(result) {
        result.put(_s.dwTrackingID, 0);
      }

      synchronized(best) {
        best.put(_s.dwTrackingID, 0);
      }
    }
  }
}

void disappearEvent(SkeletonData _s) 
{
  int id = _s.dwTrackingID;
  //println("A body disappeard. Id was " + _s.dwTrackingID);
  synchronized(bodies) {
    for (int i=bodies.size ()-1; i>=0; i--) 
    {
      if (0 == bodies.get(i).dwTrackingID) 
      {
        bodies.remove(i);
        synchronized(racquets) {
          synchronized(world) {
            world.remove(racquets.get(id));
          }
          racquets.remove(id);
        }

        synchronized(result) {
          result.remove(id);
        }

        synchronized(best) {
          best.remove(id);
        }
      }
    }
  }
  //println("Bodies size is " + bodies.size());
}

void moveEvent(SkeletonData _b, SkeletonData _a) 
{
  float deltaY, deltaX, angle;
  if (_a.trackingState == Kinect.NUI_SKELETON_NOT_TRACKED) 
  {
    return;
  }
  synchronized(racquets) {
    try {
      synchronized(world) {
        racquets.get(_a.dwTrackingID).setPosition(_a.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].x*width, _a.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].y*height);
        deltaY = _a.skeletonPositions[Kinect.NUI_SKELETON_POSITION_WRIST_RIGHT].y - _a.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].y;
        deltaX = _a.skeletonPositions[Kinect.NUI_SKELETON_POSITION_WRIST_RIGHT].x - _a.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].x;
        if (deltaX != 0) {
          angle = (float)Math.atan(Math.toRadians(deltaY/deltaX))*180/3.14;
        } else {
          if (deltaY > 0) {
            angle = 90;
          } else {
            angle = 270;
          }
        }
        racquets.get(_a.dwTrackingID).setRotation(angle);
      }
    } 
    catch (Exception e) {
      println("não falhes :(");
    }
  }

  try {
    synchronized(bodies) {
      for (int i=bodies.size ()-1; i>=0; i--) 
      {
        if (_b.dwTrackingID == bodies.get(i).dwTrackingID) 
        {
          bodies.get(i).copy(_a);
          break;
        }
      }
    }
  } 
  catch (Exception e) {
    println("SCHEEEEIIIIIIZE");
  }
}

void contactStarted(FContact c) {
  FBody body1 = c.getBody1();
  FBody body2 = c.getBody2();
  synchronized(racquets) {
    synchronized(world) {
      if (racquets.containsValue(body1)) {
        if (!racquets.containsValue(body2) && net != body2) {
          body2.addImpulse(500*(float)Math.sin(Math.toRadians(body1.getRotation())), 500*(float)Math.cos(Math.toRadians(body1.getRotation())));

          if (state == GameState.ALLAROUND) {
            incrementResultOfBody(body1);
          } else {
            updateLastTouch(body1);
          }
        }
      } else {
        if (racquets.containsValue(body2) && net != body1) {
          body1.addImpulse(500*(float)Math.sin(Math.toRadians(body1.getRotation())), 500*(float)Math.cos(Math.toRadians(body1.getRotation())));
          if (state == GameState.ALLAROUND) {
            incrementResultOfBody(body2);
          } else {
            updateLastTouch(body2);
          }
        }
      }
    }
  }
}

void incrementResultOfBody(FBody body) {
  synchronized(racquets) {
    for (Integer id : racquets.keySet ()) {
      if (racquets.get(id) == body) {
        synchronized(result) {
          result.put(id, result.get(id) + 1);

          synchronized(best) {
            if (result.get(id) > best.get(id)) {
              best.put(id, result.get(id));
            }
          }
          break;
        }
      }
    }
  }
}

void updateLastTouch(FBody body) {
  synchronized(bodies) {
    synchronized(racquets) {
      for (Integer id : racquets.keySet ()) {
        if (racquets.get(id) == body) {
          for (int i = 0; i < bodies.size (); i++) {
            if (bodies.get(i).dwTrackingID == id) {
              lastTouch = i;
              break;
            }
          }
          break;
        }
      }
    }
  }
}

//DEBUG
void drawSkeleton(SkeletonData _s) 
{
  // Body
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HEAD, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_CENTER, 
  Kinect.NUI_SKELETON_POSITION_SPINE);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_LEFT, 
  Kinect.NUI_SKELETON_POSITION_SPINE);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_SPINE);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SPINE, 
  Kinect.NUI_SKELETON_POSITION_HIP_CENTER);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_CENTER, 
  Kinect.NUI_SKELETON_POSITION_HIP_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_CENTER, 
  Kinect.NUI_SKELETON_POSITION_HIP_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_LEFT, 
  Kinect.NUI_SKELETON_POSITION_HIP_RIGHT);

  // Left Arm
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_LEFT, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_LEFT, 
  Kinect.NUI_SKELETON_POSITION_WRIST_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_WRIST_LEFT, 
  Kinect.NUI_SKELETON_POSITION_HAND_LEFT);

  // Right Arm
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_SHOULDER_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ELBOW_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_WRIST_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_WRIST_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_HAND_RIGHT);

  // Left Leg
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_LEFT, 
  Kinect.NUI_SKELETON_POSITION_KNEE_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_KNEE_LEFT, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_LEFT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_LEFT, 
  Kinect.NUI_SKELETON_POSITION_FOOT_LEFT);

  // Right Leg
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_HIP_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_KNEE_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_KNEE_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_RIGHT);
  DrawBone(_s, 
  Kinect.NUI_SKELETON_POSITION_ANKLE_RIGHT, 
  Kinect.NUI_SKELETON_POSITION_FOOT_RIGHT);
}

void DrawBone(SkeletonData _s, int _j1, int _j2) 
{
  noFill();
  stroke(255, 0, 0);
  if (_s.skeletonPositionTrackingState[_j1] != Kinect.NUI_SKELETON_POSITION_NOT_TRACKED &&
    _s.skeletonPositionTrackingState[_j2] != Kinect.NUI_SKELETON_POSITION_NOT_TRACKED) {
    line(_s.skeletonPositions[_j1].x*width, 
    _s.skeletonPositions[_j1].y*height, 
    _s.skeletonPositions[_j2].x*width, 
    _s.skeletonPositions[_j2].y*height);
  }
}

