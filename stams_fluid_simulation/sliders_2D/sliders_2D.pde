// following work done in paper: http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
// with further explanation here: http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/SmokeAndFire.pdf

import java.util.Arrays;
import controlP5.*;

ControlP5 cp5;
int N = 150;
int size = (N+2)*(N+2); // should make 100 x 100 or even 200 x 200

float dt = .1; // time
float visc = 0.001; // viscosity
float diff = 0; // diffusion rate
float source = 50; // how much density to add
float force = 1.5; // force from mouse movement for velocity
float Source_Strength = 50;
float Diffusion_Strength = 0;
float Viscosity_Strength = 0.001;
float Force_Strength = 1.5;
Slider abc;

// make velocity and density arrays, they do it one dimensionally which i guess we could also do?
// or could do two dimensionally and not need to write a translation algorithm
float[] u = new float[size];
float[] v = new float[size];
float[] u_prev = new float[size];
float[] v_prev = new float[size];

float[] dens = new float[size];
float[] dens_prev = new float[size];

int display = 0; // 0 for drawing densities, 1 for drawing velocities

void setup() {
  size(600,600); 
  noStroke();
  cp5 = new ControlP5(this);
  colorMode(RGB,1.0); // 1 is max intensity
  cp5.addSlider("Source_Strength")
    .setPosition(20, 20)
    .setRange(25, 100)
    ;
  cp5.addSlider("Diffusion_Strength")
    .setPosition(20, 30)
    .setRange(0, 0.0005)
    ;
  cp5.addSlider("Viscoscity_Strength")
    .setPosition(20, 40)
    .setRange(0, .010)
    ;
  cp5.addSlider("Force_Strength")
    .setPosition(20, 50)
    .setRange(1, 10)
    ;
    
  
  //dens_prev[idx(2,2)] = 100;
  
  //noLoop();
}

// Purpose: since our one dimensional arrays are actually two dimensional, 
// this function will take the two dimensions and squash them together
// Parameters: i is the row index, j is the column index
int idx(int i, int j) {
  return (i + (N+2)*j);
}

// Purpose: create walls around the edge -- code can be modified to create
//   other interesting boundary conditions
// Parameters: N is size, b is boundary number, x is array to be modified
void set_bnd(int N, int b, float[] x) {
  int i;
  
  for (i = 1; i <= N; i++) {
    if (b == 1) {
      x[idx(  0,i)] = -x[idx(1,i)];
      x[idx(N+1,i)] = -x[idx(N,i)];
    } else if (b != -1) {
      x[idx(  0,i)] = x[idx(1,i)];
      x[idx(N+1,i)] = x[idx(N,i)];      
    } 
    
    if (b == 2) {
      x[idx(i,  0)] = -x[idx(i,1)];
      x[idx(i,N+1)] = -x[idx(i,N)];
    } else if (b != -1) {
      x[idx(i,  0)] = x[idx(i,1)];
      x[idx(i,N+1)] = x[idx(i,N)];
    }
  }
  x[idx(  0,  0)] = 0.5*(x[idx(1,  0)]+x[idx(  0,  1)]);
  x[idx(  0,N+1)] = 0.5*(x[idx(1,N+1)]+x[idx(  0,  N)]);
  x[idx(N+1,  0)] = 0.5*(x[idx(N,  0)]+x[idx(N+1,  1)]);
  x[idx(N+1,N+1)] = 0.5*(x[idx(N,N+1)]+x[idx(N+1,  N)]);
}

// Purpose: adds a source to the density
// Parameters: N is size of one dimension, x is quite possibly the denisty array, 
//   s is all of the sources, dt is change in time
void add_source(int N, float[] x, float[] s, float dt) {
  size = (N+2)*(N+2);
  for (int i = 0; i < size; i++) {
    x[i] += dt*s[i]; // source * change in time gets added to x
  }
}

// Purpose: account for diffusion rates, both in and out using Gauss-Seidel relaxation
// Parameters: N is the size of the array, b is boundary, x is array to change, 
//   x0 is old array, diff is rate of diffusion, dt is change in time
void diffuse(int N, int b, float[] x, float[] x0, float diff, float dt) {
  int i, j, k;
  float a = dt*diff*N*N; 
  for (k = 0; k < 20; k++) {
    for (i = 1; i <= N; i++) {
      for (j = 1; j <= N; j++) { // can go up to equal bc we deal with boundary conditions below
        // LONG EQUATION BELOW: separated a bit
        // i,j is current cell
        // i-1,j is cell to the left
        // i,j+1 is cell above
        // i+1,j is cell to the right
        // i,j-1 is cell below
        float math = (x0[idx(i,j)] + a*(x[idx(i-1,j)]+x[idx(i+1,j)]+x[idx(i,j-1)]+x[idx(i,j+1)]))/(1+4*a);
        x[idx(i,j)] = math;
      }
    }
    set_bnd(N,b,x);
  }
}

// Purpose: simulates the movement of the particles through back tracing
// Parameters: N is the size of the array, b is boundary, d is the ???density??? same with d0,
//   u is the velocity in one direction and v is the velocity in another, dt is change in time
void advect(int N, int b, float[] d, float[] d0, float[] u, float[] v, float dt) {
  int i, j, i0, j0, i1, j1;
  float x, y, s0, t0, s1, t1, dt0;
  
  dt0 = dt*N;
  for (i = 1; i <= N; i++) {
    for (j = 1; j <= N; j++) {
      x = i-dt0*u[idx(i,j)]; 
      y = j-dt0*v[idx(i,j)];
      
      // make sure x is in bounds, if not, force it
      if (x < 0.5) {
        x = 0.5;  
      } else if (x > N+.05) {
        x = N+.05;
      }
      i0 = int(x);
      i1 = i0 + 1;
      
      // do the same thing for y
      if (y < 0.5) {
        y = 0.5;  
      } else if (y > N+.05) {
        y = N+.05;
      }
      j0 = int(y);
      j1 = j0 + 1;  
      
      // deal with other values
      s1 = x - i0;
      s0 = 1 - s1;
      t1 = y - j0;
      t0 = 1 - t1;
      
      // update density
      d[idx(i,j)] = s0*(t0*d0[idx(i0,j0)] + t1*d0[idx(i0,j1)]) +
                    s1*(t0*d0[idx(i1,j0)] + t1*d0[idx(i1,j1)]);
    }
  }
  set_bnd(N,b,d); 
}

// Purpose: make sure velocity field retains mass by using hodge decomposition
// Parameters: N is size, u and v are velocities, p is ???, div is ???
void project(int N, float[] u, float[]v, float[] p, float[] div) {
  int i, j, k;
  float h;
  
  h = 1.0/N;
  for (i = 1; i <= N; i++) {
    for (j = 1; j <= N; j++) {
      div[idx(i,j)] = -0.5*h*(u[idx(i+1,j)]-u[idx(i-1,j)]+
                              v[idx(i,j+1)]-v[idx(i,j-1)]);
      p[idx(i,j)] = 0;
    }
  }
  set_bnd(N,0,div);
  set_bnd(N,0,p);
  
  for (k = 0; k < 20; k++) {
    for (i = 1; i <= N; i++) {
      for (j = 1; j <= N; j++) {
        p[idx(i,j)] = (div[idx(i,j)]+p[idx(i-1,j)]+p[idx(i+1,j)]+
                                     p[idx(i,j-1)]+p[idx(i,j+1)])/4;
      }
    }
    set_bnd(N,0,p);
  }
  
  for (i = 1; i <= N; i++) {
    for (j = 1; j <= N; j++) {
      u[idx(i,j)] -= 0.5*(p[idx(i+1,j)]-p[idx(i-1,j)])/h;
      v[idx(i,j)] -= 0.5*(p[idx(i,j+1)]-p[idx(i,j-1)])/h;
    }
  }
  set_bnd(N,1,u);
  set_bnd(N,2,v);             
}

// Purpose: combine all of our steps—sources, diffusing, and advecting—into one function
// Parameters: yeah... 
void dens_step(int N, float[] x, float[] x0, float[] u, float[] v, float diff, float dt) {
  float[] tmp;
  
  add_source(N, x, x0, dt); // add our source first!

  tmp = x;
  x = x0;
  x0 = tmp;
  
  // HERE!!!
  diffuse(N,0,x,x0,diff,dt);
  tmp = x;
  x = x0;
  x0 = tmp;
  
  advect(N,0,x,x0,u,v,dt);
}


// Purpose: update the velocity based on new forces, diffusion, and advection
// Parameters: N is the size of the array, u and v are velocities (u0 and v0 are old velocities), 
//   visc is the viscocity (!!!), and dt is change in time
void vel_step(int N, float[] u, float[] v, float[] u0, float[] v0, float visc, float dt) {
  float[] tmp;
  
  add_source(N, u, u0, dt);
  add_source(N, v, v0, dt);
  
  // swap
  tmp = u;
  u = u0;
  u0 = tmp;

  diffuse(N, 1, u, u0, visc, dt);
  
  //swap
  tmp = v;
  v = v0;
  v0 = tmp;
  
  diffuse(N, 2, v, v0, Viscosity_Strength, dt); 
  
  project(N, u, v, u0, v0);
  
  //swap
  tmp = u;
  u = u0;
  u0 = tmp;
  
  tmp = v;
  v = v0;
  v0 = tmp;
  
  advect(N, 1, u, u0, u0, v0, dt);
  advect(N, 2, v, v0, u0, v0, dt); 
  
  project(N, u, v, u0, v0);
}



// Purpose: test when the mouse is being pressed in order to create densities


// Purpose: draw the velocity grid
void draw_vels() {
  int i,j;
  float x,y,h;
  
  h = width*(1./N); // partial size of each grid space
  
  //fill(.5);
  stroke(.5);
  strokeWeight(1);
  
  for (i = 1; i <= N; i++) {
    x = (i-1)*h; // offsets to where it should be
    for (j = 1; j <= N; j++) {
      y = (j)*h; // again, offsets to where it should be
      line(x,y,x+width*u[idx(i,j)],y+height*v[idx(i,j)]);
    }
  }
}

// Purpose: to draw the actual densities!
// Parameters: N is size of grid, dens is array of densities that are to be displayed!
void draw_dens(int N, float[] dens) {
  noStroke();
  int i,j;
  float x,y,h,d00,d01,d10,d11;
  
  h = width*(1./N); // partial size of each grid space
  
  for (i = 0; i <= N; i++) {
    x = (i-1)*h; // offsets to where it should be
    for (j = 0; j <= N; j++) {
      y = (j)*h; // again, offsets to where it should be
      
      
      // find densities of the four points
      d00 = dens[idx(  i,  j)];
      d01 = dens[idx(  i,j+1)];
      d10 = dens[idx(i+1,  j)];
      d11 = dens[idx(i+1,j+1)];
            
      // draw each vertex at its given color 
      beginShape();
      fill(0.1011, 0.1672, 0.9843, d00);
      vertex(x,y);
      
      fill(0.1011, 0.1672, 0.9843, d10);
      vertex(x+h,y);
      
      fill(0.1011, 0.1672, 0.9843, d11);
      vertex(x+h,y+h);
      
      fill(0.1011, 0.1672, 0.9843, d01);
      vertex(x,y+h);
      endShape();
    }
  }
}

void draw_grid() {
  int i,j;
  float h;
  stroke(120./255,130./255,255./255);
  h = width*(1./N); // partial size of each grid space

  for (i = 0; i < N; i++) {
    line(h*i,0,h*i,height);
  }
  
  for (j = 0; j < N; j++) {
    line(0,j*h,width,j*h); 
  }
  noStroke();
}

// Parameters: d is density array, u and v are velocity arrays
void testMousePressed(float[] d, float[] u, float[] v) {
  if (mousePressed) {
    // convert coordinate to grid space
    int i,j;
    
    i = int((mouseX/float(width))*N+1);
    j = int((mouseY/float(height))*N+1);
    
    // check if offscreen
    if (i < 1 || i > N || j < 1 || j > N) {
      return; 
    }

    if (mouseButton == RIGHT) {
      d[idx(i,j)] = Source_Strength;
    } 
    if (mouseButton == LEFT) {
      u[idx(i,j)] = Force_Strength*(mouseX-pmouseX);
      v[idx(i,j)] = Force_Strength*(mouseY-pmouseY);
    }
  }
}

void keyPressed() {
  if (key == ' ') {
    display = (display+1) % 2;
  }
}

void reset(float[] u, float[] v, float[] d) {
  int i;
  int size = (N+2)*(N+2);
  for (i = 0; i < size; i++) {
    u[i] = 0;
    v[i] = 0;
    d[i] = 0;
  }
}

void draw() {
  background(0); 
  
  for (int i = 0; i < 2; i++) {
    reset(u_prev,v_prev,dens_prev);
    testMousePressed(dens_prev,u_prev,v_prev); 
    vel_step(N,u,v,u_prev,v_prev,Viscosity_Strength,dt);
    //diffSlider = cp5.getController("diffSlider").getValue();
    println(Diffusion_Strength);
    dens_step(N,dens,dens_prev,u,v,Diffusion_Strength,dt);
  }

  if (display == 0) {
    draw_dens(N,dens);
  } else {
    draw_vels();
  }
}
