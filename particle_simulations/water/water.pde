import java.util.Iterator;
import java.util.Collections;
import java.util.Comparator;
import java.lang.Math;


// to store particles
ArrayList<Particle> pList = new ArrayList<Particle>();

// making things happen
float lastTime;
int spawnRate = 400; // second

// all for camera movement
PVector cPosition = new PVector(1000/2,500/2,(500/2.0) / tan(PI*30.0 / 180.0)+150);

float ry = 0;
float rx = 0;

float f = 0;

// cause i don't like having y movement 
boolean yMove = true;

// ALL FOR CAMERA MOVEMENT billboarding
float ang = 0;

// textures

int frames = 0;

PImage water;
PImage[] foam = new PImage[2];

boolean pause = false;


float whaleHeight = 0;
PVector whalePosition = new PVector(1000/2, 500+.6*500-whaleHeight, -200); 
float timeSinceMove = 10;
int direction = 1; // 1 for up, -1 for down

void setup() {
  size(1000,500,P3D);

  water = loadImage("water1.png","png");

  foam[0] = loadImage("foam1.png","png");
  foam[1] = loadImage("foam2.png","png");
  
  lastTime = millis();
  // add particles
  frameRate(200);
}

void draw() {
  background(20,63,84);

  //// calculate change in time
  float newTime = millis();
  float dt = (newTime - lastTime)/1000.0;
  lastTime = newTime;

  noStroke();
  //lights();
  
  //translate(x,0,z);
  
  // floor
  beginShape();
  fill(137,172,198);
  vertex(-10*width,height,10000);
  vertex(10*width,height,10000);
  vertex(10*width,height,-10000);
  vertex(-10*width,height,-10000);
  endShape();
  
  drawWhale();

  if (!pause) {
    // whale
    moveWhale(dt);
    // create new particles
    spawnParticles(dt);
    // simulate particles
    // deleting particles logic is taken straight from the Nature of Code reading: https://natureofcode.com/book/chapter-4-particle-systems/
    Iterator<Particle> p = pList.iterator();
    
    while (p.hasNext()) {
      Particle cur = p.next();
      cur.update(dt);
      if (cur.dead()) {
        p.remove();
      }
    }
  }
  // sort the particles from farthest from camera to closest here!
  Collections.sort(pList, new DistanceFromCamera());
  
  for (Particle part : pList) {
    part.display();
  }
      
  checkKeyHold(dt);
  moveCamera();
  
  frames += 1;
  if (frames >= 30 || pList.size() > 10000) {
    println(frameRate,pList.size());
    frames = 0;
  } 
}

void moveWhale(float dt) {
  timeSinceMove += dt;
  if (timeSinceMove > 15) {
    whaleHeight += direction*50*dt;
    if (direction == 1 && whaleHeight > 175) {
      timeSinceMove = 0; 
      direction = -1;
    } else if (direction == -1 && whaleHeight < 0) {
      timeSinceMove = 0;
      direction = 1;
    }
  }
}

void drawWhale() {
  pushMatrix();
  whalePosition.y = height+.6*height-whaleHeight; 
  
  translate(whalePosition.x,whalePosition.y,whalePosition.z);
  fill(1,14,51);
  sphere(300);
  
  translate(-135,-200,165);
  fill(255,255,255);
  sphere(20);
  
  translate(270,0,0);
  sphere(20);
  
  translate(0,-3,7);
  fill(0,0,0);
  sphere(15);
  
  translate(-270,0,0);
  sphere(15);
  
  popMatrix();
}

boolean collideWhale(Particle p) {  
  if (p.velocity.y > 0) {
    float distance = PVector.dist(whalePosition,p.position);
    float rad = 300 + p.radius; // 300 is whale radius
    if (distance < rad) { // 300 is whale radius
      // MATHS: https://studiofreya.com/3d-math-and-physics/simple-sphere-sphere-collision-detection-and-collision-response/
      // vector between them
      PVector normal = (PVector.sub(p.position,whalePosition,null)).normalize(null);
      p.position = PVector.add(whalePosition, PVector.mult(normal,rad*1.01,null),null);
      PVector vnorm = PVector.mult(normal,PVector.dot(p.velocity, normal), null);
      p.velocity.sub(vnorm);
      p.velocity.mult(.7);
      // do the maths to bounce particle
      return true;
    }
  }
  return false;
}

void spawnParticles(float dt) {
  float wholeParticles = spawnRate * dt;
  int newParticles = int(wholeParticles);
  float randPart = random(0, 1);
  if (randPart < (wholeParticles - newParticles)) {
    newParticles = newParticles + 1; 
  }
  for (int i = 0; i < newParticles; i++) {
    pList.add(new Particle());  
  }
}

class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float radius = 5;
  float resistance = .99;
  float lifetime = 0;
  int bounceNum = 0;
  PImage foamImg;
  PImage waterImg;
  boolean isFoam = false;
  
  Particle() {
    float angle = random(PI*2);
    waterImg = water;

    
    foamImg = foam[int(random(0,2))];
    if (random(0,100)<1) { // low chance it starts as foam
      isFoam = true;
    }
    
    int zCenter = -200;
    // position
    // some things just aren't worth it. circle point may be one of those things.
    float xpos = random(width/2. - 3, width/2. + 3);
    float zpos = random(zCenter - 3, zCenter + 3);
    // height+.25*height
    float ymov = random(-20,20);
    ymov = max(0,ymov); // most things will spawn at 0 still
    float ypos = min(height-radius,height - whaleHeight)-ymov;
    position = new PVector(xpos,ypos,zpos);
    
    // velocity
    float xvel, yvel, zvel;
    float tyvelOne = random(-370,-330);
    float tyvelTwo = random(-360,-330);
    yvel = tyvelOne + tyvelTwo;

    xvel = cos(angle)*(random(40,80)+random(40,80));
    zvel = sin(angle)*(random(40,80)+random(40,80));
    
    velocity = new PVector(xvel,yvel,zvel);
    acceleration = new PVector(0,565,0);
  }
  
  
  void update(float dt) {
    velocity.add(PVector.mult(acceleration,dt,null));
    velocity.add(new PVector(random(-3,3),0,random(-3,3))); //add some wiggling
    position.add(PVector.mult(velocity,dt,null));
    if (position.y + radius > height) {
      bounceNum = bounceNum + 1;
      float state = random(0,100);
      if (state>70) { // low chance it vanishes
        bounceNum = 100;
      } else if (state > 5) { // probably turns to foam
        isFoam = true;
        radius = 25;
        
        position.y = position.y - radius;
        velocity.x = velocity.x * .9;
        velocity.y = velocity.y * -.2;
        velocity.z = velocity.z * .9;
      } else { // stays as water particle
        position.y = position.y - radius;       
        velocity.x = velocity.x * .6;
        velocity.y = velocity.y * -.2;
        velocity.z = velocity.z * .6;
      }
    } else if (collideWhale(this)) {
      bounceNum = bounceNum + 1;
      float state = random(0,100);
      if (state>70) { // low chance it vanishes
        bounceNum = 100;
      } else if (state > 5) { // probably turns to foam
        isFoam = true;
        radius = 25;
      }
    }
    if (isFoam) {
      lifetime += 2*dt;
    } else {
      lifetime += dt;
    }  
  }
  
  void display() {
   
    pushMatrix();
    
    translate(position.x,position.y,position.z);
    
    // MATH: https://www.youtube.com/watch?v=puOTwCrEm7Q
    PVector f = (PVector.sub(position, cPosition, null)).normalize(null);
    PVector globalUp = new PVector(0,1,0);
    PVector r = (PVector.cross(globalUp, f, null));
    PVector up = (PVector.cross(f, r, null));
    
    //float size = radius;
    PImage curImage = waterImg;
    if (isFoam) {
      //size = 25;
      curImage = foamImg;
    }
    beginShape();
    texture(curImage);
    tint(255,225 - (lifetime*50));

    PVector first = PVector.mult((PVector.sub(up, r, null)),radius,null);
    PVector second = PVector.mult((PVector.add(up, r, null)),radius,null);
    PVector third = PVector.mult((PVector.sub(r, up, null)),radius,null);
    PVector fourth = PVector.mult((PVector.sub(PVector.mult(up,-1,null), r, null)),radius,null);

    vertex(first.x,first.y,first.z,0,0); // top left
    vertex(second.x,second.y,second.z,curImage.width,0); // top right
    vertex(third.x,third.y,third.z,curImage.width,curImage.height); // bottom right
    vertex(fourth.x,fourth.y,fourth.z,0,curImage.height); // bottom left
    endShape();
    popMatrix();
  }
  
  boolean dead() {
    if (255 - (lifetime*50) < 5) {
      return true;
    } 
    return false;
  }
}

class DistanceFromCamera implements Comparator<Particle> {
   public int compare(Particle one, Particle two)
   {
     // distance d1
     float d1 = PVector.dist(one.position, cPosition);
     float d2 = PVector.dist(two.position, cPosition);
     //https://stackoverflow.com/questions/28004269/java-collections-sort-comparison-method-violates-its-general-contract
     return -1*(new Float(d1).compareTo(d2));
   }
}

void checkKeyHold(float dt) {
  if (keyPressed) {
    if (key == 'w'){
      rx = rx + 200*dt;
      rx = rx % 360; // gave up on radians, rotating WAY too fast
    }
    if (key == 's'){
      rx = rx - 200*dt;
      rx = rx % 360;
    }
    if (key == 'a') {
      ry = ry - 200*dt;
      ry = ry % 360;
    }
    if (key == 'd') {
      ry = ry + 200*dt;
      ry = ry % 360;
    }
    if (keyCode == UP){
      f = f + 500 * dt; // how much to go forward -- split based on angle
    }
    if (keyCode == DOWN){
      f = f - 500 * dt;
    }
  }
}

void keyPressed() {
   if (keyCode == ' ') { // toggle y movement
     yMove = !yMove;
   } else if (key == 'p') {
     pause = !pause;
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
