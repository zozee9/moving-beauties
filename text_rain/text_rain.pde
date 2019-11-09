import processing.video.*;
import processing.sound.*;

// Global variables for handling video data and the input selection screen
String[] cameras;
Capture cam;
Movie mov;
PImage inputImage;
boolean inputMethodSelected = false;

// Global variables for making text rain
Quote[] quoteList;
PFont font;
float time;

// threshhold data
int threshold; //whether or not the pixel counts as blocking the rain
boolean upPressed;
boolean downPressed;
int upPressedStart; //when up started to be pressed
int downPressedStart; //when down started to be pressed
int upLastTick; //when the last up tick... ticked
int downLastTick; //when the last down tick... ticked

int spacePressed; //whether or not the space has been pressed and the image should just be black and white, 1 counts as not pressed, -1 counts as pressed
float textSpeed; //minimum speed at which the text can fall, max is .5 above it
int previousSpawnTime; //previous time a word was made
int spawnFrequency; //how often, in milliseconds, a new word

//processing sound
TriOsc tri;
boolean soundStart;
boolean soundOn;
int previousSoundSwitch; //previous time a sound was made

void setup() {
  size(1280, 720);  
  inputImage = createImage(width, height, RGB);
  font = loadFont("Noteworthy-Bold-48.vlw");
  time = 0;
  spacePressed = 1;
  
  threshold = 128;
  upPressed = false;
  downPressed = false;

  textSpeed = 15;
  spawnFrequency = 750;

  //initialize different possible quotes in setup
  quoteList = new Quote[] {new Quote("you have brains in your head you have feet in your shoes you can steer yourself any direction you choose", #7024DE),
                           new Quote("why fit in when you were born to stand out", #D618D3), 
                           new Quote("youre never too old too wacky too wild to pick up a book and read to a child", #148CC6)};

  //adding sound to my program!
  tri = new TriOsc(this);
  tri.freq(450);
  tri.amp(.15);
  soundOn = true; //whether or not sound is *currently* on
  soundStart = false; //whether or not to start playing to begin with
  previousSoundSwitch = 0;
}

void draw() {
  // When the program first starts, draw a menu of different options for which camera to use for input
  // The input method is selected by pressing a key 0-9 on the keyboard

  
  if (!inputMethodSelected) {
    cameras = Capture.list();
    int y=40;
    text("O: Offline mode, test with TextRainInput.mov movie file instead of live camera feed.", 20, y);
    y += 40; 
    for (int i = 0; i < min(9,cameras.length); i++) {
      text(i+1 + ": " + cameras[i], 20, y);
      y += 40;
    }
    return;
  }
  // This part of the draw loop gets called after the input selection screen, during normal execution of the program.

  // STEP 1.  Load an image, either from a movie file or from a live camera feed. Store the result in the inputImage variable
  
  if ((cam != null) && (cam.available())) {
    cam.read();
    inputImage.copy(cam, 0,0,cam.width,cam.height, 0,0,inputImage.width,inputImage.height);
  }
  else if ((mov != null) && (mov.available())) {
    mov.read();
    inputImage.copy(mov, 0,0,mov.width,mov.height, 0,0,inputImage.width,inputImage.height);
  }

  // Fill in your code to implement the rest of TextRain here..

  textFont(font,15);
  textAlign(CENTER,BOTTOM);
  
  changeThreshold(); //changes the threshold if button is being pressed down

  displayVideo();
  loadPixels(); //get pixel array *before* adding letters to use to figure out where letters go
  ////note: this is with the assumption that letters should *not* block other letters. it was not specified in the
  ////assignment pdf, but I believe this is a better way to do things since some letter colors would block while others would not
  ////in addition, it also simplifies how I can see whether or not a pixel should fall/raise by looking at just one rbg value
  ////and using that as a greyscale reference versus calculating it myself
 
  int timePassed = (millis() - previousSpawnTime);

  if (timePassed > spawnFrequency) { //if enough time has passed to spawn new word, update previous spawn time
    previousSpawnTime += timePassed;
  }

  while (timePassed > spawnFrequency) { //spawns a word for each second since last word spawn
    int randomQuoteInd = int(random(quoteList.length));
    quoteList[randomQuoteInd].newLetter();
    timePassed -= 1000;
  }

  for (int i = 0; i < quoteList.length; i++) {
    quoteList[i].moveLetters();
  }
  
  for (int i = 0; i < quoteList.length; i++) {
    quoteList[i].displayLetters();
  }
  
}

class Quote {
  String[] wordList;
  int colour;
  ArrayList<Letter> lettersFalling; //an array list that adds letters as they fall
  Quote(String sentence, int col) { //i want to choose the color ahead of time and not randomize it so we're passing it in, even though that makes the code less clean
    wordList = sentence.split(" ");
    lettersFalling = new ArrayList<Letter>();
    colour = col;
  }
 
  //goes through letter array and moves all letters
  void moveLetters() {
    Letter currentLetter;

    for (int i = 0; i < lettersFalling.size(); i++) {
      if (lettersFalling.get(i) != null) {
        currentLetter = lettersFalling.get(i);
        currentLetter.move(); 
        if (!currentLetter.onScreen()) { //if not still on screen, erase it to save time and memory!
          lettersFalling.remove(i);
        }
      }
    }
  }
  
  //goes through letter array and displays all letters
  void displayLetters() {
    Letter currentLetter;
    
    //set color
    fill(colour);
    for (int i = 0; i < lettersFalling.size(); i++) {
      currentLetter = lettersFalling.get(i);
      currentLetter.display();
    }
  }
   
  //the name is actually a bit of a misnomer since it will be an entire new word falling!
  //finds a random word and a random letter in that word... the random letter will start 
  //falling from the top of the screen, the rest of the letters in the word will get 
  //random positions above the screen... so it's randomized, but pre-determined
  void newLetter() {
    
    float currentXDeviance;
    int minYValue = -250; //the highest on the screen a letter can start to fall from
    //make this value larger to increase the chance of catching a word, smaller (more negative) to decrease the chance of catching a word
    String word = wordList[int(random(wordList.length))]; //chooses a word
    
    //we want at least one letter to start falling immediately with a currentYPos of 0, but that letter should be random
    int firstLetterInd = int(random(word.length()));
    float startXPos = random(width); //xposition of the first letter, letters before it can be off the screen in the left (but not right currently)
    
    currentXDeviance = startXPos;
    
    if (firstLetterInd != 0) {
      currentXDeviance -= textWidth(word.charAt(firstLetterInd-1))*random(1,2);
    }
      
    //add letters before main letter with semi-random x and y position, starting at the letter immediately to the left
    //x position is in relation to the x positions of the letters beforehand, but not constant
    int i = firstLetterInd-1;
    while (i > 0 && currentXDeviance > 0) { //only up to the second letter since finding the character at -1 would not work
      Letter currentLetter = new Letter(currentXDeviance,random(minYValue,-10),word.charAt(i));
      lettersFalling.add(currentLetter); //ahahaha everything just starts at the top rn
      currentXDeviance -= textWidth(word.charAt(i-1))*random(1,2); //anywhere between right next to the letter and twenty to the right
      i--;   
    }
    
    //need to add the very first letter separately
    lettersFalling.add(new Letter(currentXDeviance,random(minYValue,-10),word.charAt(0)));
    
    //add "main" letter
    lettersFalling.add(new Letter(startXPos,0.,word.charAt(firstLetterInd)));
    
    //add letters after main letter with semi-random x and y position
    currentXDeviance = startXPos + textWidth(word.charAt(firstLetterInd))*random(1,2);
    i = firstLetterInd+1;
    while (i < word.length() && currentXDeviance < width) { //while there are letters left in the word and they are on the screen

      Letter currentLetter = new Letter(currentXDeviance,random(minYValue,-10),word.charAt(i));
      lettersFalling.add(currentLetter); //ahahaha everything just starts at the top rn
      currentXDeviance += textWidth(word.charAt(i))*random(1,2); //anywhere between right next to the letter and twenty to the right
      i++;   
    }
  }
}
  
class Letter {
  char letter;
  float currentx, currenty;
  float speed;
  float letterWidth;
  int leftOfLetter; //sets boundaries of left of letter (if to the left of the screen, set at 0)
  int rightOfLetter; //sets boundaries of right of letter (if to the right of the screen, set at width)
  int previousFallTime; //when the letter start falling based on millis()
  int frequency;

  
  Letter (float x, float y, char let) {
    currentx = x;
    currenty = y;
    letter = let;
    letterWidth = textWidth(letter);
    leftOfLetter = getLeft();
    rightOfLetter = getRight();
    previousFallTime = millis();
    speed = random(textSpeed,2*textSpeed); //the speed of the raindrop (varying too much makes the program look bad and no longer like rain, a variation of 2x looks ok  
    //frequency = int((height-currenty)/1.5+100);
  }
  
  void display() {
    text(letter,currentx,currenty);
  }
  
  //moves the letter depending on collision
  void move() {
    
    currenty += (millis()-previousFallTime)/speed;
    //update currentTime
    previousFallTime = millis();

    int top, bottom; 
    //top of the letter
    top = getTop();
    bottom = getBottom();
    
    //uncomment following lines to see where edge detection is
    //color black = color(0,0,0);
    //set(leftOfLetter,top,black);
    //set(leftOfLetter,bottom,black);
    //set(rightOfLetter,top,black);
    //set(rightOfLetter,bottom,black);
    
    boolean collision = true; //used to keep track of whether or not there has been a collision
    
    //assume there's a collision first time through to start loop
    //loop looks to see if any of the pixels surrounding the letter are over the threshold
    //note: since this is greyscale, the red, green, and blue values will all be the same
    //as a result, I am solely looking at the red value

    while (collision && bottom > 0) {
      collision = false; //if there's no collision, it passes the loop through this
      //iterate around the edges of the pixels we just grabbed until a black one is found or all are gone through
      for (int i = leftOfLetter; i <= rightOfLetter; i++) { //if top or bottom is colliding
        if (collision == false && (red(pixels[top*width+i]) < threshold || red(pixels[bottom*width+i]) < threshold)) {
          collision = true;
        }
      }
      for (int i = top; i <= bottom; i++) {
        if (collision == false && (red(pixels[i*width+leftOfLetter]) < threshold || red(pixels[i*width+rightOfLetter]) < threshold)) {
          collision = true;
        }
      }
      if (collision == true) { //if there was a collision, move up and update top, bottom, left, right
        if (!soundStart) {
          tri.play();
          soundStart = true;
        }
        if ((millis() - previousSoundSwitch) > 1) { //this seems trivial but it seems to rid of some of the noise and skipping :D
          previousSoundSwitch = millis();
          tri.freq(int((height-currenty)/1.5+100)); //change sound if collision
        }
        currenty -= 1; //moves it up by .5
        top = getTop();
        bottom = getBottom();
      }
    }
  }
  
  
  //next four functions return placement of pixels behind edges of the letter
  //if a pixel is off the screen, just use the closest pixel on the screen 
  
  //returns top of letter
  int getTop() {
    if (currenty - textAscent() < 0) { //above top of screen
      return 0;
    }
    else if (currenty - textAscent() > height) { //below bottom of screen
      return int(height - 1);
    }
    else { //on the screen
      return int(currenty - textAscent());
    }
  }
  
  //returns bottom of letter
  int getBottom() {
    if (currenty < 0) { //above top of screen
      return 0;
    }
    else if (currenty > height) { //below bottom of screen
      return int(height-1); 
    }
    else { // on the screen
      return int(currenty);
    }
  }
  
  //returns left of letter
  int getLeft() {
    if (currentx - letterWidth/2 < 0) { //letter is to the left of the screen
      return 0;
    }
    else if (currentx - letterWidth/2 > width) { //letter is to the right of the screen
      return width-1;
    }
    else { //letter on screen
      return int(currentx - letterWidth/2);
    }
  }
  
  //returns right of letter
  int getRight() {
    if (currentx + letterWidth/2 < 0) { //letter is to the left of the screen
      return 0;
    }
    else if (currentx + letterWidth/2 > width) { //letter is to the right of the screen
      return width-1;
    }
    else { //letter on screen
      return int(currentx + letterWidth/2);
    }
  }
  
  //returns true if the letter has not fallen through the bottom of the screen, otherwise false
  boolean onScreen() {
    if (currenty < height + 25) {
      return true;
    }
    else {
      return false;
    }
  }
}

//displays the video (including the flipping of it)
void displayVideo() {
  //necessary to flip the image, scaling it by -1 makes every x pixel go reversed and setting the image x to -its width makes it so the image basically
  //draws backwards (starts at the right instead of starting at the left). works with image function but not set, not positive why.
  //could also go through and manually copy every single pixel in the pixel array, but... no.
  //not positive how push and popping matrices works other than you should do it when working with transformations
  
  //this also seems to slow my fps from ~30 to ~10 :(
  
  pushMatrix();
  scale(-1,1);

  if (spacePressed == 1) { //if we want the normal greyscale image
    image(inputImage,-inputImage.width,0);
    //filter(BLUR); //to get rid of noise, slows down program too much for me to really test:(
    filter(GRAY); //to grayscale image
  }
  else { //if we want the image to be just black or white
    image(inputImage,-inputImage.width,0);
    //filter(BLUR); //to get rid of noise, slows down program too much for me to really test :(
    filter(THRESHOLD, threshold/255.); //second value between 0 and 1
  }
  popMatrix();

}


//moves the threshold up or down by one if key is pressed
void changeThreshold() {
  if (upPressed && millis() - upLastTick > 250) { //if up is pressed and it's been quarter second since last tick
    int timePressed = millis() - upPressedStart;
    if (timePressed < 3000) { //if pressed for less than three seconds, update threshold by 1
      threshold += 1;
    }
    else { //if pressed for more than 3 seconds, update threshold by 5 (originally designed to go to increments of 10 after 10 seconds, but it wasn't helpful)
      threshold += 5;
    }
    if (threshold > 255) {
      threshold = 255;
    }
    upLastTick = millis();
  }
  else if (downPressed && millis() - downLastTick > 250) { //if down is pressed and it's been quarter second since last tick
    int timePressed = millis() - downPressedStart;
    if (timePressed < 3000) { //if pressed for less than three seconds, update threshold by 1
      threshold -= 1;
    }
    else { //if pressed for more than 3 seconds, update threshold by 5 (originally designed to go to increments of 10 after 10 seconds, but it wasn't helpful)
      threshold -= 5;
    }
    if (threshold < 0) {
      threshold = 0;
    }
   downLastTick = millis();
  }
}
  


void keyPressed() {
  if (!inputMethodSelected) {
    // If we haven't yet selected the input method, then check for 0 to 9 keypresses to select from the input menu
    if ((key >= '0') && (key <= '9')) { 
      int input = key - '0';
      if (input == 0) {
        println("Offline mode selected.");
        mov = new Movie(this, "TextRainInput.mov");
        mov.loop();
        inputMethodSelected = true;
      }
      else if ((input >= 1) && (input <= 9)) {
        println("Camera " + input + " selected.");           
        // The camera can be initialized directly using an element from the array returned by list():
        cam = new Capture(this, cameras[input-1]);
        cam.start();
        inputMethodSelected = true;
      }
      
      //set start time of program once they've chosen
      previousSpawnTime = millis();  
      //starts to play sounds after start screen
      //tri.play(); 
    }
    return;
  }


  // This part of the keyPressed routine gets called after the input selection screen during normal execution of the program
  // Fill in your code to handle keypresses here..
  
  if (key == CODED) {
    //threshold changes by predetermined amount every press
    if (keyCode == UP) {
      if (!upPressed) { //if key hasn't been processed as pressed, set time and set it as pressed
        upPressedStart = millis(); //set start of button to current time
        upLastTick = millis() - 250; //-250 so that change threshold will run first tick
        upPressed = true;
      }
    }
    else if (keyCode == DOWN) {
      if (!downPressed) { //if key hasn't been processed as pressed, set time and set it as pressed
        downPressedStart = millis(); //set start of button to current time
        downLastTick = millis() - 250; //-250 so that change threshold will run first tick
        downPressed = true;
      }
    }
  }
  else if (key == ' ') {
    // space bar pressed
    spacePressed *= -1;
  } 
  //if they press s, change the sound from being on to off or vice versa
  else if (key == 's') {
    if (soundOn) {
      tri.stop();
      soundOn = false;
    }
    else {
      tri.play();
      soundOn = true;
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    //threshold changes by predetermined amount every press
    if (keyCode == UP) {
      upPressed = false;
    }
    else if (keyCode == DOWN) {
      downPressed = false;
    }
  }
}