// following work done in paper: http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/GDC03.pdf
// with further explanation here: http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/SmokeAndFire.pdf

import java.util.Arrays;

int N = 50;
int size = (N+2)*(N+2)*(N+2); // n*2 for each of the THREE dimensions

float dt = .1; // time
float visc = 0; // viscosity
float diff = .00001; // diffusion rate
float source = 50; // how much density to add
float force = 1; // force from mouse movement for velocity

// make velocity and density arrays, they do it one dimensionally which i guess we could also do?
// or could do two dimensionally and not need to write a translation algorithm
float[] u = new float[size];
float[] v = new float[size];
float[] w = new float[size];
float[] u_prev = new float[size];
float[] v_prev = new float[size];
float[] w_prev = new float[size];

float[] dens = new float[size];
float[] dens_prev = new float[size];

float bound = .4;

int display = 0; // 0 for drawing densities, 1 for drawing velocities

PVector cPosition = new PVector(600/2,600/2,(600/2.0) / tan(PI*30.0 / 180.0)-N*4);

float ry = 0;
float rx = 0;

float f = 0;

boolean paused = false;

void setup() {
  size(600,600,P3D); 
  noStroke();
  colorMode(RGB,1.0); // 1 is max intensity
}

// Purpose: since our one dimensional arrays are actually two dimensional, 
// this function will take the two dimensions and squash them together
// Parameters: i is the row index, j is the column index, z is depth
int idx(int i, int j, int k) {
  return (i + (N+2)*(j + (N+2)*k));
}

// Purpose: create walls around the edge -- code can be modified to create
//   other interesting boundary conditions
// Parameters: N is size, b is boundary number, x is array to be modified
void set_bnd(int N, int b, float[] x) {
  int i,j;
  
  for (i = 1; i <= N; i++) {
    for (j = 1; j <= N; j++) {
      if (b == 1) {
        x[idx(  0,i,  j)] = -x[idx(1,i,j)];
        x[idx(N+1,i,  j)] = -x[idx(N,i,j)];
      } else {
        x[idx(  0,i,  j)] = x[idx(1,i,j)];
        x[idx(N+1,i,  j)] = x[idx(N,i,j)];      
      } 
      
      if (b == 2) {
        x[idx(i,  0,  j)] = -x[idx(i,1,j)];
        x[idx(i,N+1,  j)] = -x[idx(i,N,j)];
      } else {
        x[idx(i,  0,  j)] = x[idx(i,1,j)];
        x[idx(i,N+1,  j)] = x[idx(i,N,j)];
      } 
      
      if (b == 3) {
        x[idx(i,  j,  0)] = -x[idx(i,j,1)];
        x[idx(i,  j,N+1)] = -x[idx(i,j,N)];
      } else {
        x[idx(i,  j,  0)] = x[idx(i,j,1)];
        x[idx(i,  j,N+1)] = x[idx(i,j,N)];
      }
    }
  }
  x[idx(  0,  0,  0)] = (1/3)*(x[idx(1,  0,  0)]+x[idx(  0,  1,  0)]+x[idx(  0,  0,  1)]);
  x[idx(  0,N+1,  0)] = (1/3)*(x[idx(1,N+1,  0)]+x[idx(  0,  N,  0)]+x[idx(  0,N+1,  1)]);
  x[idx(N+1,  0,  0)] = (1/3)*(x[idx(N,  0,  0)]+x[idx(N+1,  1,  0)]+x[idx(N+1,  0,  1)]);
  x[idx(N+1,N+1,  0)] = (1/3)*(x[idx(N,N+1,  0)]+x[idx(N+1,  N,  0)]+x[idx(N+1,N+1,  1)]);

  x[idx(  0,  0,N+1)] = (1/3)*(x[idx(1,  0,N+1)]+x[idx(  0,  1,N+1)]+x[idx(  0,  1,  N)]);
  x[idx(  0,N+1,N+1)] = (1/3)*(x[idx(1,N+1,N+1)]+x[idx(  0,  N,N+1)]+x[idx(  0,  N+1,N)]);
  x[idx(N+1,  0,N+1)] = (1/3)*(x[idx(N,  0,N+1)]+x[idx(N+1,  1,N+1)]+x[idx(N+1,  0,  N)]);
  x[idx(N+1,N+1,N+1)] = (1/3)*(x[idx(N,N+1,N+1)]+x[idx(N+1,  N,N+1)]+x[idx(N+1,N+1,  N)]);
}

// Purpose: adds a source to the density
// Parameters: N is size of one dimension, x is quite possibly the denisty array, 
//   s is all of the sources, dt is change in time
void add_source(int N, float[] x, float[] s, float dt) {
  size = (N+2)*(N+2)*(N+2);
  for (int i = 0; i < size; i++) {
    x[i] += dt*s[i]; // source * change in time gets added to x
  }
}

// Purpose: account for diffusion rates, both in and out using Gauss-Seidel relaxation
// Parameters: N is the size of the array, b is boundary, x is array to change, 
//   x0 is old array, diff is rate of diffusion, dt is change in time
void diffuse(int N, int b, float[] x, float[] x0, float diff, float dt) {
  int i, j, k, t;
  float a = dt*diff*N*N*N; 
  for (t = 0; t < 20; t++) {
    for (i = 1; i <= N; i++) {
      for (j = 1; j <= N; j++) { 
        for (k = 1; k <= N; k++) {
          // diffuse out ones to left, right, top, bottom, in front, behind
          float math = (x0[idx(i,j,k)] + a*(x[idx(i-1,j,k)]+x[idx(i+1,j,k)]+x[idx(i,j-1,k)]+x[idx(i,j+1,k)]+x[idx(i,j,k+1)]+x[idx(i,j,k-1)]))/(1+6*a);
          x[idx(i,j,k)] = math;
        }
      }
    }
    set_bnd(N,b,x);
  }
}

// Purpose: simulates the movement of the particles through back tracing
// Parameters: N is the size of the array, b is boundary, d is the ???density??? same with d0,
//   u is the velocity in one direction and v is the velocity in another, dt is change in time
void advect(int N, int b, float[] d, float[] d0, float[] u, float[] v, float[] w, float dt) {
  int i, j, k, i0, j0, k0, i1, j1, k1;
  float x, y, z, s0, t0, u0, s1, t1, u1, dt0;
  
  dt0 = dt*N;
  for (i = 1; i <= N; i++) {
    for (j = 1; j <= N; j++) {
      for (k = 1; k <= N; k++) {
        x = i-dt0*u[idx(i,j,k)]; 
        y = j-dt0*v[idx(i,j,k)];
        z = k-dt0*w[idx(i,j,k)];
        
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
        
        // do the same thing for z
        if (z < 0.5) {
          z = 0.5;  
        } else if (z > N+.05) {
          z = N+.05;
        }
        k0 = int(z);
        k1 = k0 + 1;
        
        // deal with other values
        s1 = x - i0;
        s0 = 1 - s1;
        t1 = y - j0;
        t0 = 1 - t1;
        u1 = z - k0;
        u0 = 1 - u1;
        
        // update density
        d[idx(i,j,k)] = s0*(t0*u0*d0[idx(i0,j0,k0)] + t1*u0*d0[idx(i0,j1,k0)] + t0*u1*d0[idx(i0,j0,k1)] + t1*u1*d0[idx(i0,j1,k1)]) +
                        s1*(t0*u0*d0[idx(i1,j0,k0)] + t1*u0*d0[idx(i1,j1,k0)] + t0*u1*d0[idx(i1,j0,k1)] + t1*u1*d0[idx(i1,j1,k1)]);
      }
    }
  }
  set_bnd(N,b,d); 
}

// Purpose: make sure velocity field retains mass by using hodge decomposition
// Parameters: N is size, u and v are velocities, p is ???, div is ???
void project(int N, float[] u, float[] v, float[] w, float[] p, float[] div) {
  int i, j, k, t;
  float h;
  
  h = 1.0/N;
  for (i = 1; i <= N; i++) {
    for (j = 1; j <= N; j++) {
      for (k = 1; k <= N; k++) {
        div[idx(i,j,k)] = -(1/3)*h*(u[idx(i+1,j,k)]-u[idx(i-1,j,k)]+
                                    v[idx(i,j+1,k)]-v[idx(i,j-1,k)]+
                                    w[idx(i,j,k+1)]-w[idx(i,j,k-1)]);
        p[idx(i,j,k)] = 0;
      }
    }
  }
  
  set_bnd(N,0,div);
  set_bnd(N,0,p);
  
  for (t = 0; t < 20; t++) {
    for (i = 1; i <= N; i++) {
      for (j = 1; j <= N; j++) {
        for (k = 1; k <= N; k++) {
          p[idx(i,j,k)] = (div[idx(i,j,k)]+p[idx(i-1,j,k)]+p[idx(i+1,j,k)]+
                                           p[idx(i,j-1,k)]+p[idx(i,j+1,k)]+
                                           p[idx(i,j,k-1)]+p[idx(i,j,k+1)])/6;
        }
      }
    }
    set_bnd(N,0,p);
  }
  
  for (i = 1; i <= N; i++) {
    for (j = 1; j <= N; j++) {
      for (k = 1; k <= N; k++) {
        u[idx(i,j,k)] -= .5*(p[idx(i+1,j,k)]-p[idx(i-1,j,k)])/h;
        v[idx(i,j,k)] -= .5*(p[idx(i,j+1,k)]-p[idx(i,j-1,k)])/h;
        w[idx(i,j,k)] -= .5*(p[idx(i,j,k+1)]-p[idx(i,j,k-1)])/h;
      }
    }
  }
  set_bnd(N,1,u);
  set_bnd(N,2,v);       
  set_bnd(N,3,w);
}

// Purpose: combine all of our steps—sources, diffusing, and advecting—into one function
// Parameters: yeah... 
void dens_step(int N, float[] x, float[] x0, float[] u, float[] v, float[] w, float diff, float dt) {
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
  
  advect(N,0,x,x0,u,v,w,dt);
}


// Purpose: update the velocity based on new forces, diffusion, and advection
// Parameters: N is the size of the array, u and v are velocities (u0 and v0 are old velocities), 
//   visc is the viscocity (!!!), and dt is change in time
void vel_step(int N, float[] u, float[] v, float[] w, float[] u0, float[] v0, float[] w0, float visc, float dt) {
  float[] tmp;
  
  add_source(N, u, u0, dt);
  add_source(N, v, v0, dt);
  add_source(N, w, w0, dt);
  
  // swap
  tmp = u;
  u = u0;
  u0 = tmp;

  diffuse(N, 1, u, u0, visc, dt);
  
  //swap
  tmp = v;
  v = v0;
  v0 = tmp;
  
  diffuse(N, 2, v, v0, visc, dt); 
  
  tmp = w;
  w = w0;
  w0 = tmp;
  
  diffuse(N, 3, w, w0, visc, dt);
  
  project(N, u, v, w, u0, v0);
  
  //swap
  tmp = u;
  u = u0;
  u0 = tmp;
  
  tmp = v;
  v = v0;
  v0 = tmp;
  
  tmp = w;
  w = w0;
  w0 = tmp;
  
  advect(N, 1, u, u0, u0, v0, w0, dt);
  advect(N, 2, v, v0, u0, v0, w0, dt);
  advect(N, 3, w, w0, u0, v0, w0, dt);
  
  project(N, u, v, w, u0, v0);
}


// Purpose: draw the velocity grid
void draw_vels() {
  int i,j,k;
  float x,y,z,h;
  
  h = width*(1./N); // partial size of each grid space
  
  //fill(.5);
  stroke(.5);
  strokeWeight(1);
  
  // TODO: fix for third dimension
  
  for (i = 1; i <= N; i++) {
    x = (i-1)*h; // offsets to where it should be
    for (j = 1; j <= N; j++) {
      y = (j)*h; // again, offsets to where it should be
      for (k = 1; k <= N; k++) {
        z = -k*h+50;
        line(x,y,z,x+width*u[idx(i,j,k)],y+height*v[idx(i,j,k)],z+width*w[idx(i,j,k)]);
      }
    }
  }
}

// Purpose: to draw the actual densities!
// Parameters: N is size of grid, dens is array of densities that are to be displayed!
void draw_dens(int N, float[] dens) {
  noStroke();
  int i,j,k;
  float x,y,z,h,d000;
  
  h = width*(1./N); // partial size of each grid space
    
  for (i = 0; i <= N; i++) {
    x = (i-.5)*h; // offsets to where it should be
    for (j = 0; j <= N; j++) {
      y = (j-.5)*h; // again, offsets to where it should be
      for (k = N; k >= 0; k--) {
        z = -k*h+50;
        

        // find densities of the four points
        d000 = dens[idx(  i,  j,  k)];
        if (d000 >= bound) {
          pushMatrix();
          translate(x,y,z);
          
          //println(d000, 1-d000);
          fill(0, d000,1-d000);
          //fill(d000,0,0);
          //fill(d000);
          box(h);
          popMatrix();
        }
      }
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


// Purpose: test when the mouse is being pressed in order to create densities
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
      d[idx(i,j,(N+2)/2)] = source;
    } 
    if (mouseButton == LEFT) {
      u[idx(i,j,(N+2)/2)] = force*(mouseX-pmouseX);
      v[idx(i,j,(N+2)/2)] = force*(mouseY-pmouseY);
    }
  }
}

void keyPressed() {
  if (key == ' ') {
    display = (display+1) % 2;
  } else if (key == 'p') {
    paused = !paused; 
  } else if (key == 'r') {
    
    cPosition = new PVector(600/2,600/2,(600/2.0) / tan(PI*30.0 / 180.0)-N*4);

    ry = 0;
    rx = 0;

    f = 0;
  } else if (Character.isDigit(key)) {
    int a = Character.getNumericValue(key); 
    bound = a/10.;
    if (bound == 0) {
      bound = 1;
    }
  }
}

void checkKeyHold(float dt) {
  if (keyPressed) {
    if (key == 'w'){
      rx = rx + 20*dt;
      rx = rx % 360; // gave up on radians, rotating WAY too fast
    }
    if (key == 's'){
      rx = rx - 20*dt;
      rx = rx % 360;
    }
    if (key == 'a') {
      ry = ry - 20*dt;
      ry = ry % 360;
    }
    if (key == 'd') {
      ry = ry + 20*dt;
      ry = ry % 360;
    }
    if (keyCode == UP){
      f = f + 100*dt; // how much to go forward -- split based on angle
    }
    if (keyCode == DOWN){
      f = f - 100*dt;
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
  
  cPosition.y = cPosition.y + (cdY * f);
  
  // my position - particle position 
  camera(cPosition.x, cPosition.y, cPosition.z, cPosition.x + cdX, cPosition.y + cdY, cPosition.z + cdZ, 0, 1, 0);
    
  f = 0;
}

void reset(float[] u, float[] v, float[] w, float[] d) {
  int i;
  int size = (N+2)*(N+2)*(N+2);
  for (i = 0; i < size; i++) {
    u[i] = 0;
    v[i] = 0;
    w[i] = 0;
    d[i] = 0;
  }
}

void draw() {
  background(0); 

  if (!paused) {
    reset(u_prev,v_prev,w_prev,dens_prev);
    testMousePressed(dens_prev,u_prev,v_prev); 
    //vel_step(N,u,v,w,u_prev,v_prev,w_prev,visc,dt);
    dens_step(N,dens,dens_prev,u,v,w,diff,dt);
  }
  
  if (display == 0) {
    draw_dens(N,dens);
  } else {
    draw_vels();
  }
  
  checkKeyHold(dt);
  moveCamera();
}
