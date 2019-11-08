import java.lang.Math;
import java.util.Collections;
import java.util.Comparator;

ParticleSystem ps;
float lastTime;
float spawnRate = 20;
PImage[] star = new PImage[3];
float [] origin = {1200/2, 750, -200};

void setup () { 
  size(1200, 750, P3D);
  lastTime = millis();
  ps = new ParticleSystem(origin);
  for (int i = 0; i < 2; i++) {
    star[i] = loadImage("star" + str(i+1) + ".png","png");
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
      float x = random(1200);
      float y = random(-50,0);
      float z = random(-100,0);
      float rad = random(100);
      particles.add(new Particle(new float []{x,y,z}));
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
  float [] velocity =  {random(-35, 35), random(35), random(10)};
  float [] acceleration =  {0, 4, 0};
  float lifespan;
  int radius;
  PImage img;

  Particle(float[] a){
    position[0] = a[0];
    position[1] = a[1];
    position[2] = a[2];
    lifespan = 20;
    
    float starNum = random(0,100);
    if (starNum < 33) {
      img = star[0];
    }
    else {
      img = star[1];
    }
 }
 
  void run(float t) {
    update(t);
  }

  void update(float dt){
    velocity[0] = velocity[0] + acceleration[0] * (dt) + random(-1.,1.);
    velocity[1] = velocity[1] + acceleration[1] * (dt) + random(-.5,.5);
    velocity[2] = velocity[2] + acceleration[2] * (dt) + random(-1.,1.);
 
    position[0] = position[0] + velocity[0] * (dt);
    position[1] = position[1] + velocity[1] * (dt);
    position[2] = position[2] + velocity[2] * (dt);
 
    lifespan -= dt;
  }
  
  void display(){
    pushMatrix();
    translate(position[0], position[1], position[2]);
    beginShape();
    
    texture(img);
    
    tint(255);
    
    int size  = 15;
    vertex(-size,size,0, 0, img.height); // top left
    vertex(size,size,0, img.width, img.height); // top right
    vertex(size, -size,0, img.width, 0); // bottom right
    vertex(-size, -size, 0, 0); // bottom left
    endShape();
    popMatrix();
  }
  
  boolean isDead(){
    if(position[1] + radius > height) {
      return true;
    } else {
      return false;
    }
  }
}
  
class DistanceFromCamera implements Comparator<Particle> {
  public int compare(Particle one, Particle two) {
    //distance d1
    float d1 = one.position[2];
    float d2 = two.position[2];
      
    //float d1 = (float)Math.pow((float)Math.pow(one.position[0]-cPosition.x,2)+Math.pow((float)one.position[1]-cPosition.y,2)+Math.pow((float)one.position[2]-cPosition.z,2),.5);
    //float d2 = (float)Math.pow((float)Math.pow(two.position[0]-cPosition.x,2)+Math.pow((float)two.position[1]-cPosition.y,2)+Math.pow((float)two.position[2]-cPosition.z,2),.5);
    //https://stackoverflow.com/questions/28004269/java-collections-sort-comparison-method-violates-its-general-contract
    return 1*(new Float(d1).compareTo(d2));
  }
}

void draw() {
  fill(1,17,43,50);
  rect(0,0,width,height);
  //background(1,17,43);
  noStroke();
  float currentTime = millis();
  float dt = (currentTime - lastTime)/1000;
  lastTime=currentTime;
  //create new particles
  ps.spawnParticles(dt);  
  ps.run(dt);
  println(ps.particles.size());
  println(frameRate);
}
    
       
  
