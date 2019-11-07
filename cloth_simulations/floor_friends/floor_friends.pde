// all for camera movement
PVector cPosition = new PVector(400/2,500/2,(500/2.0) / tan(PI*30.0 / 180.0)+150);

float ry = 0;
float rx = 0;

float f = 0;

boolean move = true;
boolean drawPoints = false; // can set this to always be true--but even if its set false, it will draw points when in interactive mode

// cause i don't like having y movement 
boolean yMove = true;

// simulation info
float lastTime;

double restLen;

float k = 300; // force toward resting
float kv = 1000; // dampening
float gravity = 10; // force toward ground

Cloth c;

int curCol = 0;
int curRow = 1;

PImage tex;

float zStart = -200;
float yStart = -400;

// keys
boolean paused = true;

boolean spacePressed = false;
double timeSpacePressed = 0;

boolean upPressed = false;
double timeUpPressed = 0;

boolean downPressed = false;
double timeDownPressed = 0;

boolean leftPressed = false;
double timeLeftPressed = 0;

boolean rightPressed = false;
double timeRightPressed = 0;

void setup() {
  size(400,500,P3D);
  lastTime = millis();
  tex = loadImage("me.png");
  c = new Cloth(width,width,30,30); 
}

// contains a series of stitches
class Cloth {
  ArrayList<ArrayList<Stitch>> stitches = new ArrayList<ArrayList<Stitch>>();
  int z = 1;
  Cloth(float w, float h, int numCol, int numRow) {
    double distX = w/(numCol-1);
    double distY = h/numRow;
    double distZ = 500/(numCol-1);
        
    float leftX = width/2 - w/2;
    for (int c = 0; c < numCol; c++) {
      ArrayList<Stitch> col = new ArrayList<Stitch>();
      double[] pos = {leftX+c*distX,yStart,zStart-c*distZ};

      col.add(new Stitch(pos,false,0,0));
      for (int r = 0; r < numRow-1; r++) {
        //col.add(new Stitch(new PVector(leftX+c*distX+25*r,100+r*distY),false,c,r+1)); 
        double[] innerpos = {leftX+c*distX,yStart+(r+1)*distY,zStart-c*distZ};

        col.add(new Stitch(innerpos,true,c,r+1)); 
      }
      stitches.add(col);
      //z *= -1;
      
    }
    int rStart = numCol;
    for (int c = 0; c < numCol; c++) {
      for (int r = numRow-rStart; r < numRow; r++) {
        double[] s = stitches.get(c).get(r).pos;
        s[0] += (r-(numRow-rStart))*25;
        s[1] -= (r-(numRow-rStart))*5;
        s[2] += (r-(numRow-rStart))*10;
      }
    }

    // rest len = distance between first and last point/num points
    
    double[] first = stitches.get(0).get(0).pos;
    double[] last = stitches.get(getSize(-1)-1).get(0).pos;
    double sx,sy,sz,dist;
    
    sx = (first[0] - last[0]);
    sy = (first[1] - last[1]);
    sz = (first[2] - last[2]);

    dist = Math.sqrt(sx*sx + sy*sy + sz*sz)/numCol;
    restLen = dist;
  }
  
  void update(float dt) { 
    // update forces
    for (int c = 0; c < stitches.size(); c++) {
      for (int r = 0; r < stitches.get(c).size(); r++) {
        Stitch s = stitches.get(c).get(r);
        s.updateForces();
      }
    }
    // with all forces updated, update everything else and display
    for (int c = 0; c < stitches.size(); c++) {
      for (int r = 0; r < stitches.get(c).size(); r++) {
        Stitch s = stitches.get(c).get(r);
        s.updateAccVelPos(dt);
      }
    }
  }
  
  Stitch getPrev(int col, int row) {
    if (row == 0) {
      return null; 
    } else {
      return stitches.get(col).get(row-1);  
    }
  }
  
  Stitch getNext(int col, int row) {
    if (row >= stitches.get(col).size()-1) {
      return null;
    } else {
      return stitches.get(col).get(row+1);
    }
  }
  
  Stitch getLeft(int col, int row) {
    if (col == 0) {
      return null;
    } else {
      return stitches.get(col-1).get(row); 
    }
  }
  
  Stitch getRight(int col, int row) {
    if (col >= stitches.size()-1) {
      return null;
    } else {
      return stitches.get(col+1).get(row); 
    }
  }
  
  int getSize(int col) {
    if (col == -1) {
      return stitches.size();
    }
    return stitches.get(col).size(); 
  }
  
  void display() {
    // top left    
    
    if (drawPoints || !move) { // if we want to draw points or have the move setting turned off (interactive on), show points
      displayMesh();
    }
    
    float texW = tex.width/(getSize(-1)-1);
    float texH = tex.height/(getSize(0));
    
    fill(255,255,255);
    for (int col = 0; col < getSize(-1)-1; col++) {
      for (int row = 0; row < getSize(col)-1; row++) {
        // draw texture
        beginShape();
        //noFill();
        texture(tex);
        tint(239, 150, 190);        
        double[] first = stitches.get(col).get(row).pos;
        double[] second = stitches.get(col+1).get(row).pos;
        double[] third = stitches.get(col+1).get(row+1).pos;
        double[] fourth = stitches.get(col).get(row+1).pos;
        
        vertex((float)first[0],(float)first[1],(float)first[2],texW*col,texH*row); // top left
        vertex((float)second[0],(float)second[1],(float)second[2],texW*(col+1),texH*row); // top right
        vertex((float)third[0],(float)third[1],(float)third[2],texW*(col+1),texH*(row+1)); // bottom right
        vertex((float)fourth[0],(float)fourth[1],(float)fourth[2],texW*col,texH*(row+1)); // bottom left
        //noTint();
        endShape();
      }
    }
    
    
    // draw lines around edge
    stroke(0,0,0);
    strokeWeight(5);
    int col = 0;
    int row = 0;

    while (row < getSize(col)-1) {
      double[] cur = stitches.get(col).get(row).pos;
      double[] below = stitches.get(col).get(row+1).pos;

      line((float)cur[0],(float)cur[1],(float)cur[2],(float)below[0],(float)below[1],(float)below[2]);
      row += 1;
      if (row == getSize(col-1)-1 && col == 0) { // if finished leftmost, do rightmost
        col = getSize(-1)-1;
        row = 0;
      }
    }
    
    col = 0;
    row = 0;
    while (col < getSize(-1)-1) {
      double[] cur = stitches.get(col).get(row).pos;
      double[] right = stitches.get(col+1).get(row).pos;

      line((float)cur[0],(float)cur[1],(float)cur[2],(float)right[0],(float)right[1],(float)right[2]);
      col += 1;
      if (col == getSize(-1)-1 && row == 0) { // if finished top, do bottom
        row = getSize(col)-1;
        col = 0;
      }
    }
        
        
    noStroke();
    
  }
  
  void displayMesh() {
    for (int col = 0; col < getSize(-1); col++) {
      for (int row = 0; row < getSize(col); row++) {
        fill(0,0,0);
        //stroke(0,0,0);
        //strokeWeight(1);
        Stitch current = stitches.get(col).get(row);
        double[] cur = current.pos;
        if (curCol == col && curRow == row) { // if being controlled
        // expensive to draw all points, only draw one being controlled
          fill(239, 150, 190);
          pushMatrix();
          translate((float)cur[0],(float)cur[1],(float)cur[2]);
          sphere(current.rad);
          popMatrix();
        }
        
        // draw lines
        beginShape();

        stroke(0,0,0);
        strokeWeight(2);
        if (col < getSize(-1)-1) {
          double[] right = stitches.get(col+1).get(row).pos;
          line((float)cur[0],(float)cur[1],(float)cur[2],(float)right[0],(float)right[1],(float)right[2]);  
        }
        
        if (row < getSize(col)-1) {
          double[] below = stitches.get(col).get(row+1).pos;
          line((float)cur[0],(float)cur[1],(float)cur[2],(float)below[0],(float)below[1],(float)below[2]);
        }
        noStroke();
      }
    }
  }
}


// contains a stitch!
class Stitch {
  double pos[] = {0,0,0};
  double vel[] = {0,0,0};
  double force[] = {0,0,0};
  
  Boolean canMove = false;
  
  // point info
  float rad = 10;
  float mass = 30;
  
  // meta info
  int row;
  int col;
  
  Stitch(double[] position, Boolean move, int c, int r) {
    pos = position;
    canMove = move;
    col = c;
    row = r;
  }
  
  void updateForces() {
    double sx, sy, sz, stringLen, dampFX, dampFY, dampFZ, stringF, dirX, dirY, dirZ;
    if (!canMove) {
      return; 
    }
    
    // vertical calculations
    if (row != 0) { // if not first row
      Stitch prev = c.getPrev(col, row);
      
      sx = (pos[0] - prev.pos[0]);
      sy = (pos[1] - prev.pos[1]);
      sz = (pos[2] - prev.pos[2]);

      stringLen = Math.sqrt(sx*sx + sy*sy + sz*sz);
      dampFX = -kv * (vel[0] - prev.vel[0]); 
      dampFY = -kv * (vel[1] - prev.vel[1]); 
      dampFZ = -kv * (vel[2] - prev.vel[2]);
    
      stringF = -k * (stringLen - restLen);
      dirX = sx/stringLen;
      dirY = sy/stringLen;
      dirZ = sz/stringLen;
            
      force[1] = dampFY+stringF*dirY;
      force[0] = dampFX+stringF*dirX;
      force[2] = dampFZ+stringF*dirZ;
    }
    
    // horizontal calculations   
    // slides only listen to the right one for some reason??
    if (col != c.getSize(-1)-1) { // if last column, don't update right
      Stitch right = c.getRight(col, row);
      //Stitch left = c.getLeft(col, row);
  
      //// get one left of it
      sx = (pos[0] - right.pos[0]);
      sy = (pos[1] - right.pos[1]);
      sz = (pos[2] - right.pos[2]);
      
      stringLen = Math.sqrt(sx*sx + sy*sy + sz*sz);
      dampFX = -kv * (vel[0] - right.vel[0]); 
      dampFY = -kv * (vel[1] - right.vel[1]); 
      dampFZ = -kv * (vel[2] - right.vel[2]);

      stringF = -k * (stringLen - restLen);
      dirX = sx/stringLen;
      dirY = sy/stringLen;
      dirZ = sz/stringLen;
      
      force[1] += dampFY+stringF*dirY;
      force[0] += dampFX+stringF*dirX;  
      force[2] += dampFZ+stringF*dirZ;
    }
    
    if (col != 0) {
      
      Stitch left = c.getLeft(col, row);
  
      //// get one left of it
      sx = (pos[0] - left.pos[0]);
      sy = (pos[1] - left.pos[1]);
      sz = (pos[2] - left.pos[2]);
      
      stringLen = Math.sqrt(sx*sx + sy*sy + sz*sz);
      dampFX = -kv * (vel[0] - left.vel[0]); 
      dampFY = -kv * (vel[1] - left.vel[1]); 
      dampFZ = -kv * (vel[2] - left.vel[2]);

      stringF = -k * (stringLen - restLen);
      dirX = sx/stringLen;
      dirY = sy/stringLen;
      dirZ = sz/stringLen;
      
      force[1] += dampFY+stringF*dirY;
      force[0] += dampFX+stringF*dirX;
      force[2] += dampFZ+stringF*dirZ;
    }
  }
  
  void updateAccVelPos(float dt) {
    if (!canMove) {
      return; 
    }
    
    Stitch next = c.getNext(col, row);
    double accY = gravity + .5*force[1]/mass;
    double accX = .5*force[0]/mass;
    double accZ = .5*force[2]/mass;
    
    if (row < c.getSize(col)-1) { // if it's not the last one
      accY -= .5*(next.force[1]/next.mass);
      accX -= .5*(next.force[0]/next.mass);
      accZ -= .5*(next.force[2]/next.mass);
    }

    vel[1] += accY*dt;
    vel[0] += accX*dt;
    vel[2] += accZ*dt;
    
    pos[1] += vel[1]*dt;
    pos[0] += vel[0]*dt;
    pos[2] += vel[2]*dt;
    
    //Collision detection and response
    if (pos[1]+rad > height){
      vel[0] *= .998; // to give drag along the floor
      vel[1] *= -.9;
      vel[2] *= .998; // to give drag along the floor
      pos[1] = height - rad;   
    } 
  }
  
  void display() {
    println("drawing");
    fill(0,0,0);
    if (curCol == col && curRow == row) { // if being controlled
      fill(239, 150, 190);
    }
  
    pushMatrix();
    translate((float)pos[0],(float)pos[1],(float)pos[2]);
    sphere(rad);
    popMatrix();
    
    stroke(0,0,0);
    //if (num == 0) {
    //  line(stringPos[0],stringPos[1],stringPos,pos[0],pos[1],pos[2]);
    //} else {
    if (canMove) {
      Stitch prev = c.getPrev(col,row);
      line((float)prev.pos[0],(float)prev.pos[1],(float)prev.pos[2],(float)pos[0],(float)pos[1],(float)pos[2]);
    }
    noStroke();
    noFill();
  }
}


void checkKeyHold(float dt) {
  if (!move) {
    return; 
  }
  if (keyPressed) {
    if (key == 'w'){
      rx = rx + 400*dt;
      rx = rx % 360; // gave up on radians, rotating WAY too fast
    }
    if (key == 's'){
      rx = rx - 400*dt;
      rx = rx % 360;
    }
    if (key == 'a') {
      ry = ry - 400*dt;
      ry = ry % 360;
    }
    if (key == 'd') {
      ry = ry + 400*dt;
      ry = ry % 360;
    }
    if (keyCode == UP){
      f = f + 1000 * dt; // how much to go forward -- split based on angle
    }
    if (keyCode == DOWN){
      f = f - 1000 * dt;
    }
  }
}

void moveCamera() {
  // update x,y,z
 
  float phi = radians(rx+90); // add 90
  float theta = radians(ry-90); // sub 90

  float cdX = sin(phi)*cos(theta);
  float cdY = cos(phi);
  float cdZ = sin(phi)*sin(theta); 
    
  cPosition.x = cPosition.x + (cdX * f);
  cPosition.z = cPosition.z + (cdZ * f);
  
  if (yMove) {
    cPosition.y = cPosition.y + (cdY * f);
  }
  
  // my position - particle position 

  camera(cPosition.x, cPosition.y, cPosition.z, cPosition.x + cdX, cPosition.y + cdY, cPosition.z + cdZ, 0, 1, 0);
    
  f = 0;
}

// really ugly that this is a different function from checkKeyHold but whatever
void checkPressed(float dt) {
  if (rightPressed) {
    c.stitches.get(curCol).get(curRow).vel[0] += 1000*dt;
  }
  if (leftPressed) {
    c.stitches.get(curCol).get(curRow).vel[0] -= 1000*dt;
  }
  if (upPressed) {
    c.stitches.get(curCol).get(curRow).vel[1] -= 1000*dt;
  }
  if (downPressed) {
    c.stitches.get(curCol).get(curRow).vel[1] += 1000*dt;
  }
  
  if (spacePressed) {
    timeSpacePressed += dt;
    if (timeSpacePressed > .05) { // if it's been pressed for over a second, move
      curRow = (curRow + round(dt*50));
      if (curRow >= c.getSize(curCol)) {
        curRow = 1;
        curCol = (curCol + 1) % c.getSize(-1);
      }
      timeSpacePressed = 0;
    }
  }

}

//Allow the user to push the mass with the left and right keys
void keyPressed() {
  if (key == 'p') {
    paused = !paused; 
  }
  if (key == 'e') {
     move = !move;
     rightPressed = false;
     leftPressed = false;
     upPressed = false;
     downPressed = false;
  }
  if (key == 'r') {
    c = new Cloth(width,width,30,30);
  }
  
  if (!move) {
    if (keyCode == RIGHT) {
      rightPressed = true;
    }
    if (keyCode == LEFT) {
      leftPressed = true;
    }
    if (keyCode == UP) {
      upPressed = true;
    }
    if (keyCode == DOWN) {
      downPressed = true;
    }
    if (key == ' ') {
      spacePressed = true;
      timeSpacePressed = 1000; // will always move once
    }
  }
}

void keyReleased() {
  if (!move) {
    if (keyCode == RIGHT) {
      rightPressed = false;
    }
    if (keyCode == LEFT) {
      leftPressed = false;
    }
    if (keyCode == UP) {
      upPressed = false;
    }
    if (keyCode == DOWN) {
      downPressed = false;
    }
    if (key == ' ') {
      spacePressed = false;
    }
  }
}

void drawLights() {

  pushMatrix();
  translate(2*width, yStart, zStart);
  fill(255, 246, 160);
  sphere(100);
  
  popMatrix();
  ambientLight(200,200,200);
  pointLight(175,175,175,2*width, yStart, zStart);
}

void draw() {
  background(184, 184, 238);
  float newTime = millis();
  float realdt = (newTime-lastTime)/1000.0;
  lastTime = newTime;
  float dt =.001;
    
  drawLights();
  stroke(0,0,0);
  strokeWeight(5);
  // floor
  beginShape();
  fill(174, 237, 210);
  vertex(-6*width,height,3000);
  vertex(6*width,height,3000);
  vertex(6*width,height,-3000);
  vertex(-6*width,height,-3000);
  vertex(-6*width,height,3000);
  endShape();
  
  
  // wall
  
  beginShape();
  // 
  fill(174, 237, 210);
  
  vertex(0,yStart-5,zStart-5);
  vertex(width,yStart-5,zStart-505);
  vertex(width,height-5,zStart-505);
  vertex(0,height-5,zStart-5);
  vertex(0,yStart-5,zStart-5);

  endShape();
  
  noStroke();

  for (int i = 0; i < 300; i++) {
    if (!paused) {
      c.update(dt);
    }
  }
    
  checkKeyHold(realdt);
  checkPressed(realdt);

  moveCamera();
  c.display();
  
  
}
