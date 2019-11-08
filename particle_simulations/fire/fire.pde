import java.lang.Math;
import java.util.Collections;
import java.util.Comparator;
// used https://processing.org/examples/simpleparticlesystem.html to help with some of the finer details of the code that I adjusted for our simulation

ParticleSystem ps;

float [] origin = {1200/2, 750, -200};

float lastTime;
float spawnRate = 1550;

boolean pause = false;

// all for camera movement
PVector cPosition = new PVector(1200/2,750/2+750/4,(750/2.0) / tan(PI*30.0 / 180.0));

float ry = 0;
float rx = 0;

float f = 0;

// cause i don't like having y movement 
boolean yMove = true;

// ALL FOR CAMERA MOVEMENT billboarding
float ang = 0;

// images
PImage[] fire = new PImage[3];
PImage[] smoke = new PImage[3];

void setup () { 
  size(1200, 750, P3D);
  lastTime = millis();
  ps = new ParticleSystem(origin);
  for (int i = 0; i < 3; i++) {
    fire[i] = loadImage("fire" + str(i+1) + ".png","png");
  }
  for (int i = 0; i < 3; i++) {
    smoke[i] = loadImage("smoke" + str(i+1) + ".png","png");
  }
}

class ParticleSystem{
  ArrayList<Particle> particles;
  float [] spawnPoint = new float[3];
  
  ParticleSystem(float [] o){
    spawnPoint[0] = o[0];
    spawnPoint[1] = o[1];
    spawnPoint[2] = o[2];
    particles = new ArrayList<Particle>();
  }
  
  void spawnParticles(float dt) {
    float wholeParticles = spawnRate * dt;
    int newParticles = int(wholeParticles);
    float randPart = random(0,1);
    if (randPart < (wholeParticles - newParticles)){
      newParticles++;
    }
    for (int i = 0; i < newParticles; i++) {
      float ang = random(2*PI);
      float x = cos(ang);
      float z = sin(ang);
      float rad = random(100);
      particles.add(new Particle(new float []{(x*rad)+600+random(-10,10), height-6, (z*rad)-200+random(-10,10)}));
    }
  }
  
  void run(float t) {
    for (int i = 0; i < particles.size(); i++){
      Particle p = particles.get(i);
      p.run(t);
      //println(i);
      if (p.isDead()){
        particles.remove(i);
      }
    }
      Collections.sort(particles, new DistanceFromCamera());
      for (int i = 0; i < particles.size(); i++){
        Particle p2 = particles.get(i);
        p2.display();
      }
    //println(particles.size());
  }
}

class Particle {
  float [] position = new float[3];
  float [] velocity =  {0, random(-35), 0};
  float [] acceleration =  {0, -4, 0};
  float lifespan;
  int flickCount;
  int radius;
  PImage img;
  boolean isSmoke = false;
  
  float disFromCenter;
  
  Particle(float[] a){
    position[0] = a[0];
    position[1] = a[1];
    position[2] = a[2];
    lifespan = 10;
    flickCount = 50;
    radius = 12;
    float fireNum = random(0,100);
    if (fireNum < 5) {
      img = fire[0];
    } else if (fireNum < 15) {
      img = fire[2];
    } else {
      img = fire[1];
    }
  }
  
  void run(float t) {
    update(t);
  }
  
  void update(float dt){
    
   if (!isSmoke) {
     velocity[0] = velocity[0] + acceleration[0] * (dt) + random(-.75,.75);
     velocity[1] = velocity[1] + acceleration[1] * (dt) + random(-.5,.5);
     velocity[2] = velocity[2] + acceleration[2] * (dt) + random(-.75,.75);
   } else {
     velocity[0] = 1.01*velocity[0] + acceleration[0] * (dt) + random(-1.5,1.5);
     velocity[1] = velocity[1] + acceleration[1] * (dt) + random(-.5,.5);
     velocity[2] = 1.01*velocity[2] + acceleration[2] * (dt) + random(-1.5,1.5);
   }
   
   position[0] = position[0] + velocity[0] * (dt);
   position[1] = position[1] + velocity[1] * (dt);
   position[2] = position[2] + velocity[2] * (dt);
  
   disFromCenter = (float)Math.pow((float)Math.pow(position[0]-origin[0],2)+Math.pow((float)position[1]-origin[1],2)+Math.pow((float)position[2]-origin[2],2),.5);
   if (!isSmoke && !flicker()){
     lifespan -= (.5*dt);
   }
   else if (isSmoke || disFromCenter < 50){
     lifespan -= (dt);
   }
   else if (disFromCenter < 75){
     lifespan -= (2.1*dt);
   }
    else if (disFromCenter < 125){
     lifespan -= (2.9*dt);
    }
    else{
      lifespan -=(3.2*dt);
    }
    
    if (!isSmoke && lifespan < 0) {
      float smokeChance = random(100);
      if (smokeChance < 10) {
        isSmoke = true;
        radius = 30;
        img = smoke[int(random(3))];
        lifespan = 10;
      }
    }
  }

  boolean flicker() {
    if (flickCount == 0){
      flickCount = 50;
      return false;
    }
    if (flickCount != 50){
      return true;
    }
    float randNum = random (100);
    if (randNum < 5){
      return true;
    }
    else {
      return false;
    }
  }
  
  void display(){
    float a;
    
    if (!isSmoke && flicker() == true){
      flickCount--;
    } else {
      a = 255;

      pushMatrix();
      translate(position[0], position[1], position[2]);
      beginShape();
  
      texture(img);

      if (!isSmoke) {
        color from = color(255,212,160,255);
        color to = color(179,30,0,25);
        //color inter = lerpColor(from,to,((disFromCenter+random(-10,10))/150));
        color inter = lerpColor(from,to,((disFromCenter+random(-10,10))/150));

        tint(inter);
      } else {
        tint(255,100-((10 - lifespan)*10));
      }

      // MATH: https://www.youtube.com/watch?v=puOTwCrEm7Q
      
      PVector vPosition = new PVector(position[0],position[1],position[2]);      
      
      PVector f = (PVector.sub(vPosition, cPosition, null)).normalize(null);
      PVector globalUp = new PVector(0,1,0);
      PVector r = (PVector.cross(globalUp, f, null));
      PVector up = (PVector.cross(f, r, null));
      
      PVector first = PVector.mult((PVector.sub(up, r, null)),radius,null);
      PVector second = PVector.mult((PVector.add(up, r, null)),radius,null);
      PVector third = PVector.mult((PVector.sub(r, up, null)),radius,null);
      PVector fourth = PVector.mult((PVector.sub(PVector.mult(up,-1,null), r, null)),radius,null);
  
      vertex(first.x,first.y,first.z,0,0); // top left
      vertex(second.x,second.y,second.z,img.width,0); // top left
      vertex(third.x,third.y,third.z,img.width,img.height); // top left
      vertex(fourth.x,fourth.y,fourth.z,0,img.height); // top left
      endShape();
      popMatrix();
    }
  }
  
  boolean isDead(){
    if(lifespan < 0){
      return true;
    }
    else {
      return false;
    }
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

class DistanceFromCamera implements Comparator<Particle> {
   public int compare(Particle one, Particle two)
   {
     //distance d1
     PVector onePV = new PVector(one.position[0], one.position[1], one.position[2]);
     PVector twoPV = new PVector(two.position[0], two.position[1], two.position[2]);
     float d1 = PVector.dist(onePV, cPosition);
     float d2 = PVector.dist(twoPV, cPosition);
      
     //float d1 = (float)Math.pow((float)Math.pow(one.position[0]-cPosition.x,2)+Math.pow((float)one.position[1]-cPosition.y,2)+Math.pow((float)one.position[2]-cPosition.z,2),.5);
     //float d2 = (float)Math.pow((float)Math.pow(two.position[0]-cPosition.x,2)+Math.pow((float)two.position[1]-cPosition.y,2)+Math.pow((float)two.position[2]-cPosition.z,2),.5);
     //https://stackoverflow.com/questions/28004269/java-collections-sort-comparison-method-violates-its-general-contract
     return -1*(new Float(d1).compareTo(d2));
   }
}
 
  
void draw() {
  background(2,15,51);
  noStroke();
  beginShape();
  fill(48,23,2);
  vertex(-width,height,1000);
  vertex(2*width,height,1000);
  vertex(2*width,height,-1000);
  vertex(-width,height,-1000);
  endShape();
  
  float currentTime = millis();
  float dt = (currentTime - lastTime)/1000;
  lastTime=currentTime;
  if (!pause) {
   //create new particles
    ps.spawnParticles(dt);  
    ps.run(dt);
  }
  
  checkKeyHold(dt);
  moveCamera();
  println(ps.particles.size());
  println(frameRate);
}
