// testing github

import java.util.*;
//import java.util.Collections;
//import java.util.Comparator;
//import java.util.PriorityQueue;

ArrayList<Agent> agents = new ArrayList<Agent>();
ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();

PRM prm;

// scale factor
float mult = 30;
// we should move this, but also need it for c-space
float agentRad = .25*mult;

// user interaction
int mode = 0; // 0 --> create circles, 1 --> move circles, 2 --> make agent
PVector clickPos;
Obstacle currentObstacle = null;

boolean drawPaths = false;
boolean drawPoints = false;

// agent movement
float lastTime;
PVector[] Forces;

void setup() {
  size(600,600);

  //obstacles.add(new Obstacle(new PVector(width/2,height/2),2*mult));
  //obstacles.add(new Obstacle(new PVector(width/2+100,height/2+100),2*mult));
  prm = new PRM();
  
  //agents.add(new Agent(new PVector(mult, height-mult), new PVector(width-1*mult,1*mult), agentRad));
  //agents.add(new Agent(new PVector(mult, mult), new PVector(width-1*mult,height-1*mult), agentRad));
    
  Forces = new PVector[agents.size()];
    
  lastTime = millis();
}

class PRM {
  ArrayList<PVector> points = new ArrayList<PVector>();
  ArrayList<Integer> UCSPoints = new ArrayList<Integer>();
  ArrayList<Integer> AStarPoints = new ArrayList<Integer>();
  float rad = .25*mult;
  float[][] matrix;  
  
  // creating a PRM goes through all the obstacles and adds together all of their points
  PRM() {
    // NEED TO GET RID OF THIS LINE
    for (int i = 0; i < obstacles.size(); i++) {
      points.addAll(obstacles.get(i).points);
    }
    points.add(null);
    points.add(null);
    // AND GET RID OF THIS ONE!
    int size = points.size();
    matrix = new float[size][size];
    // if points don't collide with obstacle,
    // IGNORE LAST TWO THINGS!!! those are just placeholders :) 
    PVector from, to;
    float dist;
    for (int i = 0; i < size-2; i++) {
      from = points.get(i);
      for (int j = i+1; j < size-2; j++) {
        to = points.get(j);
        dist = PVector.dist(from,to);
        // check dist first, to short circuit
        if (dist == 0 || isValidPath(from,to)) {
          matrix[i][j] = dist;
          matrix[j][i] = dist;
        } else { // invalid path
          matrix[i][j] = 0;
          matrix[j][i] = 0;
        }
      }
    }
  }
  
  // update the matrix to include a start and end point
  void updateMatrix(PVector start, PVector end) {
    points.set(matrix.length-2, start);
    points.set(matrix.length-1, end);
    PVector from,to;
    float dist;
    // update last two rows first
    for (int i = matrix.length-2; i < matrix.length; i++) {
      from = points.get(i);
      for (int j = 0; j < matrix.length; j++) {
        to = points.get(j);
        dist = PVector.dist(from,to);
        // check dist first, to short circuit
        if (dist == 0 || isValidPath(from,to)) {
          matrix[i][j] = dist;
          matrix[j][i] = dist;
        } else { // invalid path
          matrix[i][j] = 0;
          matrix[j][i] = 0;
        }        
      }
    }    
  }
  
  // returns all the valid paths from a point
  ArrayList<Integer> getNeighbors(int i) {
    ArrayList<Integer> neighbors = new ArrayList<Integer>();
    float[] row = matrix[i];
    for (int j = 0; j < row.length; j++) {
      if (row[j] != 0) {
        neighbors.add(j);
      }
    }
    return neighbors;
  }

  // heuristic for A*
  float heuristic(PVector start, PVector end){
    float h = end.dist(start);
    return h;
  }
  
  // uniform cost search
  ArrayList<PVector> aStarSearch(PVector start, PVector end) {
    // matrix updates for the specific agent :))
    updateMatrix(start, end); 
    // priority queue needs to keep track of key, value pairs
    // prioritizes based on cost
    int[] path = new int[points.size()]; // keep track of parent of each! used at end
    for (int i = 0; i < path.length; i++) {
      path[i] = -1;
    }
    int index = -1;
    
    NodeComparator compare = new NodeComparator();
    PriorityQueue<Node> q = new PriorityQueue<Node>(compare); // queue for search, frontier
    q.add(new Node(start,0,matrix.length-2));
    ArrayList<Integer> explored = new ArrayList<Integer>(); // list of all explored points
    // can check if a point is in it by comparing explored.indexOf(x) != -1
    
    // while there is stuff left in the queue
    while (q.size() != 0) {
      Node n = q.remove(); // remove the lowest-cost thing
      PVector current = n.pos;
      index = n.ind;
      if (current.x == end.x && current.y == end.y) { // if closest is end, we done!
        break; 
      }
      
      explored.add(n.ind); // add key to explored list
      // go through each of the neighbors
      
      ArrayList<Integer> neighbors = getNeighbors(index);

      for (int neighborIndex : neighbors) { 
        boolean inQ = false;
        float cost = 0;
        Iterator<Node> itr = q.iterator();
        Object o = null;
        while (itr.hasNext()) {
           Node elem = itr.next();
           if (elem.ind == neighborIndex) {
             o = elem;
             inQ = true; 
             cost = elem.val;
           }
        }
        float newCost = n.val + matrix[index][neighborIndex];
        // if it's connected path and vertex has not yet been explored and it isn't in queue
        if (explored.indexOf(neighborIndex) == -1 && !inQ) { // if it's not disconnected
          // i is the key, value is value associated with n + value distance between it and n
          // because n.value will be keeping track of the cumulative distance thus far!
          q.add(new Node(points.get(neighborIndex),newCost+heuristic(points.get(neighborIndex),end),neighborIndex)); // add to neighbors list (may have already been checked though!
          // TODO: when adding distance, add in distance from point i to end
          path[neighborIndex] = index; // parent is the current element we found the neighbors of
        } else if (inQ && cost > newCost) { 
          q.remove(o);
          q.add(new Node(points.get(neighborIndex),newCost+heuristic(points.get(neighborIndex),end),neighborIndex));
          path[neighborIndex] = index;
        }
      }
    }    
    
    //println("ASTAR!!!");
    //println(path);
    //for (int i = 0; i < path.length; i++) {
    //  if (path[i] != -1) {
    //    AStarPoints.add(i);
    //  }
    //}
    //UCS(start,end);
    // take path list and change it to the corresponding pvectors
    ArrayList<PVector> vectorPath = new ArrayList<PVector>();
    int pathIndex = path.length-1;
    // while the next one leads to a valid point (allows us to not add the current position);
    while (path[pathIndex] != -1 ) {
      vectorPath.add(points.get(pathIndex));
      pathIndex = path[pathIndex];
    }
    Collections.reverse(vectorPath);    
    return vectorPath;
  }

  // uniform cost search
  ArrayList<PVector> UCS(PVector start, PVector end) {
    // matrix updates for the specific agent :))
    updateMatrix(start, end); 
    // priority queue needs to keep track of key, value pairs
    // prioritizes based on cost
    int[] path = new int[points.size()]; // keep track of parent of each! used at end
    for (int i = 0; i < path.length; i++) {
      path[i] = -1;
    }
    int index = -1;
    
    NodeComparator compare = new NodeComparator();
    PriorityQueue<Node> q = new PriorityQueue<Node>(compare); // queue for search, frontier
    q.add(new Node(start,0,matrix.length-2));
    ArrayList<Integer> explored = new ArrayList<Integer>(); // list of all explored points
    // can check if a point is in it by comparing explored.indexOf(x) != -1
    
    // while there is stuff left in the queue
    while (q.size() != 0) {
      Node n = q.remove(); // remove the lowest-cost thing
      PVector current = n.pos;
      index = n.ind;
      if (current.x == end.x && current.y == end.y) { // if closest is end, we done!
        break; 
      }
      
      explored.add(n.ind); // add key to explored list
      // go through each of the neighbors
      
      ArrayList<Integer> neighbors = getNeighbors(index);

      for (int neighborIndex : neighbors) { 
        boolean inQ = false;
        float cost = 0;
        Iterator<Node> itr = q.iterator();
        Object o = null;
        while (itr.hasNext()) {
           Node elem = itr.next();
           if (elem.ind == neighborIndex) {
             o = elem;
             inQ = true; 
             cost = elem.val;
           }
        }
        float newCost = n.val + matrix[index][neighborIndex];
        // if it's connected path and vertex has not yet been explored and it isn't in queue
        if (explored.indexOf(neighborIndex) == -1 && !inQ) { // if it's not disconnected
          // i is the key, value is value associated with n + value distance between it and n
          // because n.value will be keeping track of the cumulative distance thus far!
          q.add(new Node(points.get(neighborIndex),newCost,neighborIndex)); // add to neighbors list (may have already been checked though!
          // TODO: when adding distance, add in distance from point i to end
          path[neighborIndex] = index; // parent is the current element we found the neighbors of
        } else if (inQ && cost > newCost) { 
          q.remove(o);
          q.add(new Node(points.get(neighborIndex),newCost,neighborIndex));
          path[neighborIndex] = index;
        }
      }
    }    
    
    println("UCS");
    println(path);
    for (int i = 0; i < path.length; i++) {
      if (path[i] != -1) {
        UCSPoints.add(i);
      }
    }
    // take path list and change it to the corresponding pvectors
    ArrayList<PVector> vectorPath = new ArrayList<PVector>();
    int pathIndex = path.length-1;
    // while the next one leads to a valid point (allows us to not add the current position);
    while (path[pathIndex] != -1 ) {
      vectorPath.add(points.get(pathIndex));
      pathIndex = path[pathIndex];
    }
    Collections.reverse(vectorPath);    
    return vectorPath;
  }
  
  void display() {
    PVector from, to;
    int size = points.size()-2;
    stroke(0,0,0);
    // graph is symetrical since getting from A -> B == B -> A
    // only need to draw i to everything after i (hack)
    for (int i = 0; i < size; i++) { // from
      from = points.get(i);
      // draw the point!
      if (drawPoints) {
        displayPoint(i);
      }
      if (drawPaths) {
        for (int j = i+1; j < size; j++) { // to
          to = points.get(j);
          if (matrix[i][j] != 0) { // if path exists
            stroke(0,0,0);
            line(from.x, from.y, to.x, to.y);
          }
        }
      }
    }
  }
  
  void displayPoint(int ind) {
    PVector pos = points.get(ind);
    boolean inUCS = !(-1 == UCSPoints.indexOf(ind));
    boolean inAStar = !(-1 == AStarPoints.indexOf(ind));
    //boolean inAStar
    if (!inUCS && !inAStar) {
      fill(155,155,155); 
    } else if (inUCS && inAStar) {
      fill(102,255,102);
    } else if (inUCS) {
      fill(51,153,255);
    } else { // in astar
      fill(255,255,0);
    }
    pushMatrix();
    translate(pos.x, pos.y);
    ellipse(0,0,rad*2,rad*2);
    popMatrix();
  }
}

// just for the Priority Queue
class Node {
  PVector pos;
  float val;
  int ind;
  Node(PVector position, float value, int index) {
    pos = position;
    val = value;
    ind = index;
  }
}

class NodeComparator implements Comparator<Node> {
  int compare(Node one, Node two) {
    if  (one.val> two.val) {
      return 1;
    } else if (two.val > one.val) {
      return -1;
    } else {
      return 0;
    }
  }
}

boolean isValidPath(PVector from, PVector to) {
  // math from class wasn't working: 
  // https://stackoverflow.com/questions/1073336/circle-line-segment-collision-detection-algorithm
  PVector f;
  float a, b, r, c, disc, t1, t2;

  PVector d = PVector.sub(to,from,null);
      
  for (int i = 0; i < obstacles.size(); i++) {
    Obstacle o = obstacles.get(i);
    f = PVector.sub(from, o.pos, null);
    a = PVector.dot(d,d);
    b = 2*PVector.dot(f,d);
    r = o.rad + agentRad;
    c = PVector.dot(f,f) - r*r;
    
    disc = b*b - 4*a*c;
    if (disc >= 0) { // roots are complex and different
      disc = sqrt(disc);
      t1 = (-b - disc)/(2*a);
      t2 = (-b + disc)/(2*a);
      if (!((t1 < 0 || t1 > 1) && (t2 < 0 || t2 > 1))) {
        return false;
      }
      if (PVector.dist(from, o.pos) <= o.rad + agentRad) {
        return false;
      }
    }
  }  
  return true;
}


// an agent! they just doin their best out here to get to their goal without hittin the obstacles
class Agent {
  PVector goal;
  PVector oldPos;
  PVector pos;
  float rad;
  float speed = 100;
  PVector vel;
  PVector goalVel;
  
  ArrayList<PVector> path;
  int state = 0;

  // TODO: store path and state along path
  // store path as nodes?
  
  // creates a generic agent with a position and radius
  Agent(PVector pos, PVector goal, float rad) {
    this.oldPos = pos;
    this.pos = pos;
    this.rad = rad;
    this.goal = goal;
    
    this.vel = new PVector(0,0,0);
    this.goalVel = new PVector(0,0,0);
    updatePath(); 
  }
  
  void updatePath() {
    goalVel = new PVector(0,0,0);
    path = prm.aStarSearch(pos, goal); 
    state = 0;
  }
  
  void update() {
  // if we haven't already reached the goal, then move 
    if (state != path.size()) {
      // find the furthest visible node on path
      boolean foundPath = false;
      while(state < path.size() && isValidPath(pos,path.get(state))) {
        state++;
        foundPath = true;
      }
      state--; // we shoot over by one, so just decrement
      // if the planned back no longer exists, go find a new one :((
      if (!foundPath) {
        updatePath();
        update();
        return;
      }

      // direction from where we are to where we want to be
      PVector dir = PVector.sub(path.get(state), pos, null);
      PVector dirNorm = dir.normalize(null);
      
      float distEnd = PVector.dist(goal, pos);
      float currentSpeed = speed;
      
      // slow down near the end! so we don't overshoot it and cry :)
      if (distEnd < 125) {
        currentSpeed = pow(distEnd,.85); 
      }
      
      // move in that direction by some variation of dt
      goalVel = PVector.mult(dirNorm, currentSpeed);
    }
  }
  
  // display the agent on the screen
  void display() {
    noStroke();
    fill(0,0,0);
    pushMatrix();
    translate(pos.x,pos.y);
    ellipse(0,0,rad*2,rad*2);
    popMatrix();
  }
  
  void displayGoal() {
    noStroke();
    fill(255,155,155);
    pushMatrix();
    translate(goal.x,goal.y);
    ellipse(0,0,rad*2,rad*2);
    popMatrix();
  }
}

// these are all circles for now, could do some fun inheritance if we wanna be fancy
class Obstacle {
  // list of all possible points around obstacle
  ArrayList<PVector> points;
  PVector pos;
  float rad;
  boolean isHovered = false;
  
  // creates a generic obstacle with a position and radius
  Obstacle(PVector pos, float rad) {
    this.pos = pos;
    this.rad = rad;
    // TODO: create points for the path around the obstacle
    setObstaclePoints();
  }
  
  void updateObstaclePosition(PVector pos) {
    this.pos = pos;
    setObstaclePoints();
  }
  
  void updateObstacleRadius(float rad) {
    this.rad = rad;
    setObstaclePoints();
  }

  
  // creates points around the c-obstacle. 
  // set points to be hexagon surrounding the circle
  void setObstaclePoints() { 
    float offsetMid = .707*(rad+agentRad+20);
    float offsetSide = 1*(rad+agentRad+20);
    points = new ArrayList<PVector>();
    
    points.add(new PVector(pos.x, pos.y + offsetSide));
    points.add(new PVector(pos.x + offsetMid, pos.y + offsetMid));
    points.add(new PVector(pos.x + offsetSide, pos.y));
    points.add(new PVector(pos.x - offsetMid, pos.y + offsetMid));
    points.add(new PVector(pos.x, pos.y - offsetSide));
    points.add(new PVector(pos.x - offsetMid, pos.y - offsetMid));
    points.add(new PVector(pos.x - offsetSide, pos.y));
    points.add(new PVector(pos.x + offsetMid, pos.y - offsetMid));     
  }
  
  ArrayList<PVector> getObstaclePoints() {
    return points;
  }
  
  // return true if obstacle is hovered over, else false
  boolean isHovered() {
    return isHovered; 
  }
  
  // Sees if a point is in the obstacle space, also taking into account the 
  // radius of what would be colliding with the obstacle. Allows us to not have 
  // to account for collision later (hopefully).
  boolean pointIn(PVector pointPos, float bufferRad) {
    // calculate the distance between the middle of the obstacle and the middle of the point
    float dist = PVector.dist(pos,pointPos);
    
    // if that distance is greater than the radius of the obstacle plus the radius passed in 
    // then the point is in the C-obstacle, so return true. Otherwise, the point is not in this 
    // c-obstacle (but could still be in another!!!)
    float cObstacleRad = rad + bufferRad; // radius of the C-Obstacle
    if (dist <= cObstacleRad) {
      return true;
    }
    return false;
  }
  
  
  // returns true if mouse is over the circle. Also sets a class variable to represent this.
  boolean mouseHovered() {
    PVector mousePos = new PVector(mouseX, mouseY);
    float dist = PVector.dist(pos,mousePos);
    
    if (dist <= rad) {
      isHovered = true;
      return true;
    }
    isHovered = false;
    return false; 
  }
  
  // display the obstacle on the screen
  void display() {
    noStroke();
    fill(165,75,175);
    if (isHovered) {
      fill(2,123,230); 
    }
    pushMatrix();
    translate(pos.x,pos.y);
    ellipse(0,0,rad*2,rad*2);
    popMatrix();
  }
}


float TTC(Agent i, Agent j){
  float r = i.rad + j.rad;
  //PVector w = new PVector(0,0,0);
  PVector w = PVector.sub(j.pos, i.pos, null); //j pos - i pos
  float c = w.dot(w) - r*r;
  if(c < 0) { //agents are colliding
    return 0;
  }
  
  PVector v = new PVector(0,0,0);
  PVector.sub(i.vel, j.vel, v); // i velocity - j velocity
  float a = v.dot(v);
  float b = w.dot(v);
  float discr = b*b - a*c;
  
  if(discr <= 0){
    return Float.POSITIVE_INFINITY; //return infinity
    //return 0; //return infinity
  }
  
  float tau = (b - sqrt(discr))/a;
  
  if(tau < 0){
    return Float.POSITIVE_INFINITY; //return infinity
    //return 0; //return infinity
  }
  return tau;
} 

void TimeToCollisionAvoidanceAlgorithm(ArrayList<Agent> agents, PVector[] Forces, float dt){
  float t = 0; //time, add in better value
  float tH = 5;
  float maxF = 1000;
  
  //for each agent i
    //find all neighbors within sensing radius
        
  //for (Agent i : agents) {
  for(int i = 0; i < agents.size(); i++){ //for each agent i
    Forces[i] = PVector.sub(agents.get(i).goalVel,  agents.get(i).vel, null); //compute goal force: Forces[i] = 2 * gv[i] - v[i]
    Forces[i] = PVector.mult(Forces[i],2,null);
    
    for(int j = 0; j < agents.size(); j++){ //for each neighboring agent j
    
      if( i != j){
        //compute ttc
        t = TTC(agents.get(i),agents.get(j));
        if(t != Float.POSITIVE_INFINITY){
          //t = 10;
          //compute collision avoidance force
          //force Direction 
          PVector FAvoid = new PVector(0,0,0);
          
          //FAvoid = x[i] + v[i]*t - x[j] - v[j]*t
          // FAvoid = x[i] + infinite*v[i] - x[j] - infinite*v[j]
          FAvoid.add(agents.get(i).vel);
          FAvoid.sub(agents.get(j).vel);
          FAvoid.mult(t);
          FAvoid.add(agents.get(i).pos);
          FAvoid.sub(agents.get(j).pos);
                    
          if(FAvoid.x != 0 && FAvoid.y != 0){
            FAvoid = PVector.div(FAvoid,sqrt(FAvoid.dot(FAvoid)),null);
          }
  
          //force Magnitude
          float mag = 0;
          
          if (t >= 0 && t <= tH){
            mag = (tH - t) / (t + 0.001);
          }
          
          if (mag > maxF){
            mag = maxF;
          }
          
          FAvoid.mult(mag);
          Forces[i].add(FAvoid);
        }
      }
    }
  }
  
  for(int i = 0; i < agents.size(); i++){ 
    agents.get(i).vel.add(PVector.mult(Forces[i],dt,null));
    agents.get(i).pos.add(PVector.mult(agents.get(i).vel, dt, null));
  } 
}


void mousePressed() {
  clickPos = new PVector(mouseX, mouseY); 
  
  if (mode == 0) { // if in create mode
    // create a new obstacle at the default radius where clicked
    Obstacle c = new Obstacle(clickPos,0);
    obstacles.add(c);
    currentObstacle = c;
  } else if (mode == 1) { // if in move mode
    // iterate backwards through obstacles to look at most recently made first
    for (int i = obstacles.size()-1; i >= 0; i--) {
      Obstacle o = obstacles.get(i);
      if (o.isHovered()) {
        currentObstacle = o;
      }
    }
  } 
}

void mouseDragged() {
  PVector currentPos = new PVector(mouseX, mouseY);
  if (mode == 0) {
    float rad = PVector.dist(currentPos, clickPos);
    currentObstacle.updateObstacleRadius(min(235,rad));
    prm = new PRM();
    for (int i = 0; i < agents.size(); i++) {
      Agent a = agents.get(i);
      a.updatePath();
    }
  } else if (mode == 1 && currentObstacle != null) {
    currentObstacle.updateObstaclePosition(currentPos);
    prm = new PRM();
    for (int i = 0; i < agents.size(); i++) {
      Agent a = agents.get(i);
      a.updatePath();
    }
  }
}

void mouseReleased() {
  PVector currentPos = new PVector(mouseX, mouseY);
  
  if (mode == 0) {
    float rad = PVector.dist(currentPos, clickPos);
    currentObstacle.updateObstacleRadius(min(235,rad));
    prm = new PRM();
    for (int i = 0; i < agents.size(); i++) {
      Agent a = agents.get(i);
      a.updatePath();
    }
  } else if (mode == 1 && currentObstacle != null) {
    currentObstacle.updateObstaclePosition(currentPos);
      prm = new PRM();
      for (int i = 0; i < agents.size(); i++) {
        Agent a = agents.get(i);
        a.updatePath();
      }
  } 
  else if (mode == 2) {
    agents.add(new Agent(clickPos, currentPos, agentRad)); 
    Forces = new PVector[agents.size()];
  }
  currentObstacle = null;
}

void keyPressed() {
  if (key == ' ') {
    mode = (mode + 1)%3;
  }
}

// in charge of displaying all relevant information
void display() {
  for (int j = 0; j < obstacles.size(); j++) {
    Obstacle o = obstacles.get(j);    
    // probably shouldn't test hovering here, but leaving it for now
    o.mouseHovered();
    o.display();
  }
  
  prm.display();
  for (int i = 0; i < agents.size(); i++) {
    agents.get(i).displayGoal();
  }
  
  for (int i = 0; i < agents.size(); i++) {
    agents.get(i).display();
  }
}

void update(float dt) {
  for (int i = 0; i < agents.size(); i++) {
    Agent a = agents.get(i);
    a.update();
  }
  TimeToCollisionAvoidanceAlgorithm(agents, Forces, dt);
}

void draw() {
  float newTime = millis();
  float dt = (newTime-lastTime)/1000.0;
  lastTime = newTime;
  
  background(255,255,255);
  update(dt);
  display();
}