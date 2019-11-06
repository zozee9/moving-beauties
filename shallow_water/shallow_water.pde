// all for camera movement
PVector cPosition;

int frames = 0;

float ry = 0;
float rx = 0;

float f = 0;

// cause i don't like having y movement 
boolean yMove = true;
boolean showLines = false;


// for the actual water simulation
float lastTime;

float sim_dt = .00075;
float w;
float g = 10;
double damp = 1;

// system state variables
int nx = 100;
float dx;
double[] h = new double[nx]; // height vector
double[] uh = new double[nx]; // momentum vector

// helper variables
float totlen = nx*dx;
double[] hm = new double[nx]; // midpoint height vector
double[] uhm = new double[nx]; // midpoint momentum vector

void setup() {
  size(1000,600,P3D);
  lastTime = millis();
  
  w = -width;
  
  dx = width / nx; // space to fill / number of things
  
  cPosition = new PVector(width/2,height/2,(height/2.0) / tan(PI*30.0 / 180.0)+150);
  
  for (int i = 0; i < nx; i++) {
    h[i] = 100;  
  }
  for (int i = 0; i < nx/4; i++) {
    h[i] += i*5; 
  }
  for (int i = nx/4; i < nx/2; i++) {
    h[i] += 5*(nx/4) - (i-nx/4)*5;
  }
}

void waveEquation() {
  // compute halfstep for midpoints
  for (int i = 0; i < nx-1; i++) {
    //hm[i] = (h[i]+h[i+1])/2.0 - (sim_dt/2.0)*(uh[i]+uh[i+1])/dx;
    hm[i] = (h[i]+h[i+1])/2.0 - (sim_dt/2.0)*(uh[i]+uh[i+1])/dx;
    uhm[i] = (uh[i]+uh[i+1])/2.0 - (sim_dt/2.0)*(Math.pow((uh[i+1]),2)/h[i+1] + .5*g*Math.pow((h[i+1]),2) - Math.pow((uh[i]),2)/h[i] - .5*g*Math.pow((h[i]),2))/dx;
  }
  
  // then fullstep
  for (int i = 0; i < nx-2; i++) {
    h[i+1] -= sim_dt*(uhm[i+1]-uhm[i])/dx;
    //uh[i+1] -= sim_dt*(damp*uh[i+1]+Math.pow((uhm[i+1])/hm[i+1],2) + .5*g*Math.pow((hm[i+1]),2) - Math.pow((uhm[i])/hm[i],2) - .5*g*Math.pow((hm[i]),2))/dx;
    uh[i+1] -= sim_dt*(damp*uh[i+1]+Math.pow(uhm[i+1],2)/hm[i+1] + .5*g*Math.pow(hm[i+1],2) - Math.pow(uhm[i],2)/hm[i] - .5*g*Math.pow(hm[i],2))/dx;
  }
  
  // reflective boundary conditions
  h[0] = h[1];
  h[h.length-1] = h[h.length-2];
  uh[0] = -uh[1];
  uh[uh.length-1] = -uh[uh.length-2];
}

void update(float dt) {
  //for (int i = 0; i < int(dt/sim_dt); i++) {
  for (int i = 0; i < 100; i++) {
    waveEquation();
  }
}

void display() {
  if (showLines) {
    stroke(0,0,0); 
  }
  for (int i = 0; i < nx; i++) {
    float x1,x2;
    
    x1 = i*dx;
    x2 = (i+1)*dx;

    float h1 = (float)h[i];
    float h2;
    if (i < nx - 2) {
      h2 = (float)h[i+1];
    } else {
      h2 = h1;
    }
    

    fill(125,125,255);
    beginShape();
    vertex((float)x1,height-h1,0); // front left
    vertex((float)x2,(float)(height-h2),0); // front right
    vertex((float)x2,(float)(height-h2),w); // back right
    vertex((float)x1,height-h1,w); // back left
    endShape();
    
    beginShape();
    vertex((float)x1,height-h1,0); // front top left
    vertex((float)x2,height-h2,0); // front top right
    vertex((float)x2,height,0); // front bottom right
    vertex((float)x1,height,0); // front top left
    endShape();
  }
  noStroke();
}


void checkKeyHold(float dt) {
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

void drawLights() {
  //fill(255, 246, 160);
  //pushMatrix();
  //translate(width+50, 150, w/2);
  //sphere(50);
  //popMatrix();
  //noFill();
  
  ambientLight(200,200,200);
  pointLight(175,175,175,width+50, 150, w/2);
}

void draw() {
  background(255,255,255);
  
  float newTime = millis();
  float dt = (newTime-lastTime)/1000.0;
  lastTime = newTime;
  
  noFill();
  drawLights();
  stroke(0,0,0);
  // fake box, won't bound water yet lol
  pushMatrix();
  // box starts at height 0
  translate(width/2,height - height/4,w/2);
  box(width,height/2,w);
  popMatrix();
  noStroke();
  
  update(dt);
  
  checkKeyHold(dt);
  moveCamera();
  
  // draw da water
  display();
  
  frames += 1;
  if (frames >= 30) {
    println(frameRate);
    frames = 0;
  } 
  
}
