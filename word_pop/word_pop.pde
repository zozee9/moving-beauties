//balloon tap game wentz101
import java.util.ListIterator;

import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

import processing.sound.*;

// using merriam-websters dictionary api: https://www.dictionaryapi.com/products/api-collegiate-dictionary
// api key: 59937348-a0db-4974-8942-b7f95c55dcb0
// request url: https://www.dictionaryapi.com/api/v3/references/collegiate/json/voluminous?key=your-api-key

// available letters
// based on english scrabble letter distributions https://en.wikipedia.org/wiki/Scrabble_letter_distributions#English
// TODO: blank letters?
String LETTERS = "EEEEEEEEEEEEAAAAAAAAAIIIIIIIIIOOOOOOOONNNNNNRRRRRRTTTTTTLLLLLLSSSSUUUUDDDDGGGBBCCMMPPFFHHVVWWYYKJXQZ";
int TOPBARHEIGHT = 70;

PFont font;
PFont bigFont;
PFont hugeFont;

// icons from https://icons8.com/icons
PImage homeIcon;
PImage restartIcon;
PImage exitIcon;
PImage nextIcon;
PImage prevIcon;

// images for rules
PImage screenImage;

SoundFile buttonSound;
SoundFile popSound;
SoundFile wrongSound;
SoundFile rightSound;

// buttons
ArrayList<Button> buttons = new ArrayList<Button>();
int SQUAREWIDTH = 70;
int SMALLSQUAREWIDTH = 60;

// rule page
int rulePage = 0;
int maxPages = 3;

// word info
HashMap<Character, Integer> letterValues = new HashMap<Character, Integer>();
int[] lengthBonuses = {0,0,0,0,1,1,3,5,9};

HttpURLConnectionWordSearch http = new HttpURLConnectionWordSearch();

// list of balloons
ArrayList<Balloon> balloons = new ArrayList<Balloon>();

// current word being formed
String currentWord;
String lastWord;

int totalScore;
int lastScore;
int maxScore;

String bestWord;
int bestWordScore;

boolean validEntry;

// time
float lastFrameTime;

float timeSinceLastSpawn;

float BASESPAWNRATE = .25;
float currentSpawnRate;

float secondsLeft;

enum State {
  START, RULES, CREDITS, PLAYING, END
}

State playState;

void setup()
{
  size(700,700); 
  
  surface.setTitle("Word Pop");
  
  font = loadFont("Chalkboard-Bold-24.vlw");
  bigFont = loadFont("Chalkboard-Bold-48.vlw");
  hugeFont = loadFont("Chalkboard-Bold-56.vlw");
  
  homeIcon = loadImage("home.png");
  restartIcon = loadImage("play.png");
  exitIcon = loadImage("exit.png");
  nextIcon = loadImage("nextArrow.png");
  prevIcon = loadImage("prevArrow.png");
  
  screenImage = loadImage("whole2.png");
  
  buttonSound = new SoundFile(this, "pling.wav");
  popSound = new SoundFile(this, "blop.wav"); // Mark DiAngelo
  wrongSound = new SoundFile(this, "wrong.wav"); // Mark DiAngelo
  rightSound = new SoundFile(this, "right.wav"); // Mark DiAngelo

  textFont(font, 24);
  textAlign(CENTER, CENTER);
  
  strokeWeight(5);
  
  try {
    http.sendGet("");
  } catch (Exception e) { 
    println("Failed original send get");
  }  
  
  setLetterValues();
  
  // get max score from file, if it exists (else max is 0)
  String[] stringFile = loadStrings("maxScore.txt");
  if (stringFile != null) {
    maxScore = Integer.parseInt(stringFile[0]);
  }
  
  switchState(State.START);
  
  if (stringFile == null) { // if no max score, start with rules
    switchState(State.RULES);
  }
}

void setLetterValues() {  
  letterValues.put('A',1);
  letterValues.put('B',3);
  letterValues.put('C',3);
  letterValues.put('D',2);
  letterValues.put('E',1);
  letterValues.put('F',4);
  letterValues.put('G',2);
  letterValues.put('H',4);
  letterValues.put('I',1);
  letterValues.put('J',8);
  letterValues.put('K',5);
  letterValues.put('L',1);
  letterValues.put('M',3);
  letterValues.put('N',1);
  letterValues.put('O',1);
  letterValues.put('P',3);
  letterValues.put('Q',10);
  letterValues.put('R',1);
  letterValues.put('S',1);
  letterValues.put('T',1);
  letterValues.put('U',1);
  letterValues.put('V',4);
  letterValues.put('W',4);
  letterValues.put('X',8);
  letterValues.put('Y',4);
  letterValues.put('Z',10);
}

void draw()
{
  background(0,125,125);
 
  if (playState == State.START) {
    startGame();
  } 
  
  if (playState == State.RULES) {
    showRules(); 
  }
  
  if (playState == State.CREDITS) {
    showCredits(); 
  }  
  
  if (playState == State.PLAYING) {
    playGame();
  } 
  
  // not an elif since playGame can short circuit into end game state
  if (playState == State.END) {
    endGame(); 
  }
}

void restartGame() {
  balloons.clear(); // restart balloons
  
  // current word being formed
  currentWord = "";
  lastWord = "";
  
  totalScore = 0;
  lastScore = 0;
  
  bestWord = "";
  bestWordScore = Integer.MIN_VALUE;
  
  timeSinceLastSpawn = 1;
  currentSpawnRate = 0;

  secondsLeft = 60;
  
  lastFrameTime = millis();
}

void playGame() { 
  // calculate change in time
  float newTime = millis();
  float dt = (newTime - lastFrameTime)/1000.0;
  
  lastFrameTime = newTime;
  secondsLeft -= dt; // less time left
  
  if (secondsLeft <= 0) { // no time left, end now!
    switchState(State.END);
    return;
  }
  
  // move and draw current balloons, will loop twice
  moveBalloons(dt);
  drawBalloons();
  
  // spawn new balloons
  timeSinceLastSpawn += dt;
  if (timeSinceLastSpawn > currentSpawnRate) {
    // spawn new balloon
    balloons.add(new Balloon());
    
    // get next spawn time
    currentSpawnRate = random(BASESPAWNRATE*.9,BASESPAWNRATE*1.1);
    
    // reset time
    timeSinceLastSpawn = 0;
  }
  
  displayTopBar();
}

void startGame() {
  displayTopBar();
  displayStartScreen();  
}

void showRules() {
  displayTopBar();
  displayRules();
}


void showCredits() {
  displayTopBar();
  displayCredits();
}

void endGame() {
  drawBalloons();
  displayTopBar();
  displayEndScreen();
}

void switchState(State state) {
  playState = state;
  rulePage = 0; // only need to do this when exiting rules, but this is easier
  buttons.clear();
  
  switch(state) {
    case START:
      restartGame();

      float distance = height/7;
      buttons.add(new StartButton(width/2-(SQUAREWIDTH*3/2),height/3,SQUAREWIDTH*3,SQUAREWIDTH,"START"));
      buttons.add(new RulesButton(width/2-(SQUAREWIDTH*3/2),height/3+distance,SQUAREWIDTH*3,SQUAREWIDTH,"RULES"));
      buttons.add(new CreditsButton(width/2-(SQUAREWIDTH*3/2),height/3+2*distance,SQUAREWIDTH*3,SQUAREWIDTH,"CREDITS"));
      buttons.add(new ExitButton(width/2-(SQUAREWIDTH*3/2),height/3+3*distance,SQUAREWIDTH*3,SQUAREWIDTH,"EXIT"));
      break;
    case RULES:      
      buttons.add(new ArrowButton(width/2+1.7*SMALLSQUAREWIDTH,height/1.225,SMALLSQUAREWIDTH,SMALLSQUAREWIDTH,nextIcon,1));
      break;
    case CREDITS:
      buttons.add(new HomeButton(width/2-(SMALLSQUAREWIDTH*3/2),height/1.225,SMALLSQUAREWIDTH*3,SMALLSQUAREWIDTH,"HOME"));
      break;
    case PLAYING:
      // restart
      restartGame();
      break;
    case END:
      // write high score to file :) 
      saveMaxScore();
    
      // create end buttons
      buttons.add(new HomeButton(width/2-2*SQUAREWIDTH,height/2 + height/3.5,SQUAREWIDTH,SQUAREWIDTH,homeIcon));
      buttons.add(new StartButton(width/2-SQUAREWIDTH/2,height/2 + height/3.5,SQUAREWIDTH,SQUAREWIDTH,restartIcon));
      buttons.add(new ExitButton(width/2+SQUAREWIDTH,height/2 + height/3.5,SQUAREWIDTH,SQUAREWIDTH,exitIcon));
      break;
    default:
      break;
  }
}

void showButtons() {
  for (Button button : buttons) {
    button.display(); 
  }
}

void displayTopBar() {
  // draw info up top, offset of 5 to help with drawing edges
  fill(255,255,255);
  rect(2.5,2.5,width-5,TOPBARHEIGHT-5);
 
  fill(0,0,0);
  
  // points
  int score = scoreWord(currentWord);
  
  // at least three letters
  String dashes = "";
  for (int i = currentWord.length() - 3; i < 0; i++) {
    dashes += "-";
  }
  
  // total score on right
  // should be right aligned
  textFont(font, 24);

  textAlign(RIGHT,CENTER);
  text("SCORE: "+String.valueOf(totalScore),width-TOPBARHEIGHT/2,TOPBARHEIGHT/2);
  textAlign(CENTER,CENTER);
  
  // word in middle
  text(currentWord + dashes + " (" + String.valueOf(score) + ")",width/2,TOPBARHEIGHT - TOPBARHEIGHT/1.5);
  
  // last word below word
  if (lastWord != "") {
    textFont(font, 16);
    if (validEntry) {
      fill(0,225,100);
      text(lastWord + " (+" + String.valueOf(lastScore) + ")",width/2,TOPBARHEIGHT - TOPBARHEIGHT/4);

    } else {
      fill(255,0,50);
      text(lastWord + " (" + String.valueOf(lastScore) + ")",width/2,TOPBARHEIGHT - TOPBARHEIGHT/4);
    }
    textFont(font, 24);
  }

  // timer on left
  fill(0,0,0);
  ellipse(TOPBARHEIGHT*.5, TOPBARHEIGHT/2, TOPBARHEIGHT*.75, TOPBARHEIGHT*.75);
  
  fill(255,255,255);
  // timer should round up? never thought about this before huh
  text(ceil(secondsLeft),TOPBARHEIGHT/2,TOPBARHEIGHT/2);
}

void displayMiddleBox() {
  // put gray overlay over screen
  fill(0,0,0,75);
  noStroke();
  rect(0,0,width,height);
  stroke(0,0,0);
  
  // finish box
  fill(255,255,255);
  rect(width/4,height/8,width/2,height/1.25,25); 
}

void displayStartScreen() {
  displayMiddleBox();
  
  // start name
  fill(0,0,0);
  textFont(hugeFont,56);
  text("WORD POP!",width/2,height/5);
  
  fill(115,115,115);
  textFont(font,20);
  text("by Zoë Wentzel",width/2,height/5+50);

  showButtons();
}

void displayEndScreen() {
  displayMiddleBox();
  
  // category names
  fill(115,115,115);
  textFont(bigFont,32);
  text("SCORE",width/2,height/3);
  text("HIGH SCORE",width/2,height/2);
  text("BEST WORD",width/2,height/2 + height/6);

  // category info
  fill(0,0,0);
  if (bestWordScore != Integer.MIN_VALUE) {
    text(bestWord + " (" + String.valueOf(bestWordScore) + ")",width/2,height/2 + height/6 + 36);
  } else {
    text("N/A",width/2,height/2 + height/6 + 36);
  }
  
  textFont(hugeFont,56);
  text("GAME OVER!",width/2,height/5);
  text(totalScore,width/2,height/3+36);
  text(maxScore,width/2,height/2+36);

  showButtons();
}

void displayRules() {
  displayMiddleBox();
  
  fill(0,0,0);
  textFont(hugeFont,56);
  text("RULES",width/2,height/5);
  
  float distance;
  float start;
  textFont(font,18);
  textAlign(LEFT,CENTER);
  if (rulePage == 0) {
    distance = 30;
    start = height/3.25;

    text("• Get points from clicking on\nletters to form a word",width/3.5,start);
    text("• Rare letters and longer words\nare worth more!",width/3.5,start+2.25*distance);
    text("• Words must be at least three\nletters",width/3.5,start+4.5*distance);
    text("• Hit [SPACE] to submit a word",width/3.5,start+6.25*distance);
    text("• But be careful — submit\na word that doesn't exist and\nlose half the points its worth!",width/3.5,start+8.5*distance);
    text("• Score as many points as\npossible in 60 seconds",width/3.5,start+11*distance);    
  } else if (rulePage == 1) {
    image(screenImage,width/2-150,height/2-150,300,300.*(220./804.));

    distance = 60;
    start = height/2-distance/2.5;
    
    text("• Seconds Remaining: game ends\nafter all 60 seconds pass",width/3.5,start);
    text("• Word: the current letters entered",width/3.5,start+distance);
    text("• Word Score: how much the word\nwill be worth if valid",width/3.5,start+2*distance+5);
    text("• Total Score: score so far this\ngame (can be negative!)",width/3.5,start+3*distance+20);
  } else if (rulePage == 2) {
    distance = 30;
    start = height/3.25;
    
    text("• 1 point: E, A, I, O, N, R, T, L, S, U",width/3.2,start+distance);
    text("• 2 points: D, G",width/3.2,start+2*distance);
    text("• 3 points: B, C, M, P",width/3.2,start+3*distance);
    text("• 4 points: F, H, V, W, Y",width/3.2,start+4*distance);
    text("• 5 points: K",width/3.2,start+5*distance);
    text("• 8 points: J, X",width/3.2,start+6*distance);
    text("• 10 points: Q, Z",width/3.2,start+7*distance);
    
    text("*Letter values and frequencies\ntaken from Scrabble",width/3.5,start+9.5*distance);
    
    textFont(bigFont,24);
    text("LETTER VALUES:",width/3.5,start);
  } else if (rulePage == 3) {
    distance = 30;
    start = height/3.25;

    //int[] lengthBonuses = {0,0,0,0,1,1,3,5,9};
    text("• +1 for 4 or 5 letters",width/3.2,start+distance);
    text("• +3 for 6 letters",width/3.2,start+2*distance);
    text("• +5 for 7 letters",width/3.2,start+3*distance);
    text("• +9 for 8+ letters",width/3.2,start+4*distance);
    text("• +2 extra per letter past 8",width/3.2,start+5*distance);

    text("Longer words with uncommon letters\nwill usually be worth the most.",width/3.5,start+7*distance);

    textFont(bigFont,24);
    text("WORD VALUES:",width/3.5,start);
    
    textFont(hugeFont,56);
    textAlign(CENTER,CENTER);
    text("Good luck!",width/2,start+9.5*distance);

  }
  textAlign(CENTER,CENTER);
  
  showButtons();
}

void displayCredits() {
  displayMiddleBox();
  
  fill(0,0,0);
  textFont(hugeFont,56);
  text("CREDITS",width/2,height/5);
  
  float distance = height/11;
  float extraDistance = 24;
  float startY = height/3.5;
  
  
  textFont(font,24);
  text("Zoë Wentzel",width/2,startY+extraDistance);
  text("https://icons8.com",width/2,startY+extraDistance+distance);
  text("Mark DiAngelo",width/2,startY+extraDistance+2*distance);
  text("Scrabble",width/2,startY+extraDistance+3*distance);
  text("Merriam-Webster's\nCollegiate® Dictionary\nwith Audio",width/2,startY+60+4*distance);

  textFont(font,18);
  fill(115,115,115);
  text("MADE BY",width/2,startY);
  text("ICONS FROM",width/2,startY+distance);
  text("SOUNDS BY",width/2,startY+2*distance);
  text("LETTER VALUES FROM",width/2,startY+3*distance);
  text("DICTIONARY API",width/2,startY+4*distance);
  
  showButtons();
}

int scoreWord(String word) {
  int wordScore = 0;
  for (int i = 0; i < word.length(); i++) {
    wordScore += letterValues.get(word.charAt(i));
  }
  
  // bonus based on length of word, lengthBonusIdx + 1 per extra letter past 9
  int lengthBonusIdx = min(word.length(), lengthBonuses.length-1);
  // second part is the extra letter bonus - 1 per letter past 9
  int lengthBonus = lengthBonuses[lengthBonusIdx] + 2*max(0,word.length() - lengthBonusIdx);
  wordScore += lengthBonus;
  
  return wordScore;
}

int updateScore(String word, boolean pass) {
  int wordScore = scoreWord(word);
  int scoreAdjust;
  if (pass) {
    scoreAdjust = wordScore; 
  } else { // lose half the points if it's invalid
    scoreAdjust = -ceil(wordScore/2.0);
  }
  
  totalScore += scoreAdjust;
  
  return scoreAdjust;
}

void saveMaxScore() {
  if (totalScore > maxScore) {
    maxScore = totalScore;
    String[] maxScoreArray = {String.valueOf(totalScore)};
    saveStrings("maxScore.txt",maxScoreArray);
  }
}

void moveBalloons(float dt) { 
  ListIterator<Balloon> iter = balloons.listIterator();
  while(iter.hasNext()) {
    Balloon balloon = iter.next();

    // if it's onscreen, move and display it
    if (!balloon.isAboveScreen()) {
      balloon.move(dt);
    } else { // otherwise remove it      
      iter.remove();
    }
  }
}

void drawBalloons() {
  for (Balloon balloon : balloons) {
    balloon.display();
  }
}

void checkWord() {
  HttpAsyncRequest obj = new HttpAsyncRequest(currentWord); 
  HttpAsyncResponseListener mListener = new HttpAsyncResponseListener(); 
  obj.registerHttpAsyncResponseListener(mListener); 
  obj.sendHttpRequest(); 
  
  currentWord = ""; 
}

color randomColorSkewed() {
  return color(random(75,200), random(75,200), random(75,200));
}

class Balloon {
  float rad;
  color col;
  
  PVector pos;
  float speed;
  
  char letter;
  
  // balloon is in charge of all its random data... might be bad? idk
  Balloon() {
    rad = random(20,30); 
    col = randomColorSkewed();
    pos = new PVector(random(0,width+rad), height+rad);
    speed = random(75,175);
    letter = LETTERS.charAt(int(random(0,LETTERS.length())));
  }
  
  void move(float dt) {
    // make it go up the screen
    pos.y -= speed*dt;
  }
  
  char getLetter() {
    return letter; 
  }
  
  // return true if the pvector given is within the circle
  boolean isIn(float xPos, float yPos) {
    PVector mousePos = new PVector(xPos, yPos);
    // if dist < rad then in
    if (pos.dist(mousePos) < rad) {
      return true;
    }
    return false;
  }
  
  // returns true if balloon is above the playable screen
  boolean isAboveScreen() {
    if (pos.y + rad < TOPBARHEIGHT) {
      return true; 
    }
    return false;
  }
  
  void display() {
    fill(col);
    ellipse(pos.x,pos.y,rad*2,rad*2); // circle doesn't exist in my version RIP
    
    textFont(font, 24);
    fill(255,255,255);
    text(letter,pos.x,pos.y);
  }
}


// taken from: https://www.geeksforgeeks.org/asynchronous-synchronous-callbacks-java/
class HttpAsyncRequest { 
  private HttpAsyncResponseListener mListener; // listener field 
  private String word;

  HttpAsyncRequest(String word) {
    this.word = word; 
  }
  
  public void registerHttpAsyncResponseListener(HttpAsyncResponseListener mListener) 
  { 
    this.mListener = mListener; 
  } 

  // will asynchronously send the http request -- gets rid of lag!
  public void sendHttpRequest() 
  { 
    // An Async task always executes in new thread 
    new Thread(new Runnable() { 
      public void run() 
      {  
        boolean pass = false;
        
        // at least three letters long
        if (word.length() >= 3) {
          try {
            pass = http.sendGet(word);
          } catch (Exception e) { 
            println("Failed send get");
          }
        }
        
        // make sure listener is registered. 
        if (mListener != null) { 
          // invoke the callback method of class A 
          mListener.onHttpAsyncResponseEvent(word, pass); 
        } 
      } 
    }).start(); 
  } 
} 
  
class HttpAsyncResponseListener { 
  public void onHttpAsyncResponseEvent(String word, boolean pass) 
  { 
    // if we entered an actual word!
    if (word.length() != 0) {
      if (pass) {
        rightSound.play(); 
      } else {
        wrongSound.play(); 
      }
      
      // update score
      int score = updateScore(word, pass); // whether it passes or fails
    
      lastScore = score;
      lastWord = word;
      
      validEntry = pass;
    
      // see if it's the best word so far
      if (score > bestWordScore) {
        bestWordScore = score;
        bestWord = word;
      }
    }
  } 
} 

// https://www.mkyong.com/java/how-to-send-http-request-getpost-in-java/  
class HttpURLConnectionWordSearch {
  boolean sendGet(String word) throws Exception {
    String url = "https://www.dictionaryapi.com/api/v3/references/collegiate/json/"+word+"?key=59937348-a0db-4974-8942-b7f95c55dcb0";
    URL obj = new URL(url);
    
    HttpURLConnection con = (HttpURLConnection) obj.openConnection();
    
    con.setRequestMethod("GET");
    int responseCode = con.getResponseCode();
    
    if (responseCode != 200) {
      println("Bad response code:", responseCode);
      return false; 
    }   
        
    BufferedReader in = new BufferedReader(
      new InputStreamReader(con.getInputStream()));
    String inputLine;
    StringBuffer response = new StringBuffer();

    // only read the first line, we don't actually care about the data
    if ((inputLine = in.readLine()) != null) {
      response.append(inputLine);
    }
    in.close();
    
    // if second char is { then it's valid :')
    if (response.toString().charAt(1) == '{') {
       return true;
    }
    return false;
  }
}

// button class - abstract
abstract class Button {
  PVector pos;
  float sWidth;
  float sHeight;
  
  color col;
  
  String text = ""; // will have text as an image in the future, this is a hack

  PImage img;
  
  boolean isHovered = false;
  
  Button(float xPos, float yPos, float sWidth, float sHeight, PImage img) {
    this.pos = new PVector(xPos,yPos);
    this.sWidth = sWidth;
    this.sHeight = sHeight;
    this.img = img;
    this.col = color(255,255,255);
  }
  
  Button(float xPos, float yPos, float sWidth, float sHeight, String text) {
    this.pos = new PVector(xPos,yPos);
    this.sWidth = sWidth;
    this.sHeight = sHeight;
    this.text = text;
    this.col = color(255,255,255);
  }
  
  void display() {
    fill(col);
    rect(pos.x,pos.y,sWidth,sHeight,15);
    if (img != null) {
      int offset = 5;
      image(img,pos.x+offset,pos.y+offset,sWidth-offset*2,sHeight-offset*2);
    }
    
    fill(0,0,0);
    textFont(bigFont,48);
    text(text,pos.x+sWidth/2,pos.y+sHeight/2);
  }
    
  boolean isIn(float oXPos, float oYPos) {
    if ((oXPos > pos.x) && (oXPos < pos.x + sWidth) && (oYPos > pos.y) && (oYPos < pos.y + sHeight)) {
      return true;
    }
    return false;
  }
  
  void setHovered(boolean hovered) {
    // if going from not hover to hover
    if (hovered && !this.isHovered) {
      col = randomColorSkewed();
      this.isHovered = hovered; 
    } // if going from hover to not hover
    else if (!hovered && this.isHovered) {
      col = color(255,255,255);
      this.isHovered = hovered; 
    }
  }
  
  void clickedOn() {
    buttonSound.play(); 
  }
}

class StartButton extends Button {
  StartButton(float xPos, float yPos, float sWidth, float sHeight, PImage img) {
    super(xPos,yPos,sWidth,sHeight,img); 
  }
  
  StartButton(float xPos, float yPos, float sWidth, float sHeight, String text) {
    super(xPos,yPos,sWidth,sHeight,text); 
  }

  // what happens when the button is clicked on
  void clickedOn() {
    super.clickedOn();
    switchState(State.PLAYING);
  }
}

class RulesButton extends Button {  
  RulesButton(float xPos, float yPos, float sWidth, float sHeight, String text) {
    super(xPos,yPos,sWidth,sHeight,text); 
  }

  // what happens when the button is clicked on
  void clickedOn() {
    super.clickedOn();
    switchState(State.RULES);
  }
}

class CreditsButton extends Button {  
  CreditsButton(float xPos, float yPos, float sWidth, float sHeight, String text) {
    super(xPos,yPos,sWidth,sHeight,text); 
  }

  // what happens when the button is clicked on
  void clickedOn() {
    super.clickedOn();
    switchState(State.CREDITS);
  }
}

class ExitButton extends Button {
  ExitButton(float xPos, float yPos, float sWidth, float sHeight, PImage img) {
    super(xPos,yPos,sWidth,sHeight,img); 
  }
  
  ExitButton(float xPos, float yPos, float sWidth, float sHeight, String text) {
    super(xPos,yPos,sWidth,sHeight,text); 
  }

  // what happens when the button is clicked on
  void clickedOn() {
    exit();
  }
}

class HomeButton extends Button {
  HomeButton(float xPos, float yPos, float sWidth, float sHeight, PImage img) {
    super(xPos,yPos,sWidth,sHeight,img); 
  }
  
  HomeButton(float xPos, float yPos, float sWidth, float sHeight, String text) {
    super(xPos,yPos,sWidth,sHeight,text); 
  }

  // what happens when the button is clicked on
  void clickedOn() {
    super.clickedOn();
    switchState(State.START);
  }
}

class ArrowButton extends Button {
  int dir;
  
  ArrowButton(float xPos, float yPos, float sWidth, float sHeight, PImage img, int dir) {
    super(xPos,yPos,sWidth,sHeight,img); 
    this.dir = dir;
  }

  // what happens when the button is clicked on
  void clickedOn() {
    super.clickedOn();
    if (rulePage == 0) { // if it was the first page, add back button (since it won't be the first one anymore)
      buttons.add(new ArrowButton(width/2-2.7*SMALLSQUAREWIDTH,height/1.225,SMALLSQUAREWIDTH,SMALLSQUAREWIDTH,prevIcon,-1));
    } else if (rulePage == maxPages) { // if it was the last page, add the forward button and get rid of home
      buttons.clear();
      buttons.add(new ArrowButton(width/2-2.7*SMALLSQUAREWIDTH,height/1.225,SMALLSQUAREWIDTH,SMALLSQUAREWIDTH,prevIcon,-1));
      buttons.add(new ArrowButton(width/2+1.7*SMALLSQUAREWIDTH,height/1.225,SMALLSQUAREWIDTH,SMALLSQUAREWIDTH,nextIcon,1));
    }
    
    rulePage += dir;

    if (rulePage == 0) { // first page
      buttons.clear();
      buttons.add(new ArrowButton(width/2+1.7*SMALLSQUAREWIDTH,height/1.225,SMALLSQUAREWIDTH,SMALLSQUAREWIDTH,nextIcon,1));
    } else if (rulePage == maxPages) { // last page
      buttons.clear();
      buttons.add(new ArrowButton(width/2-2.7*SMALLSQUAREWIDTH,height/1.225,SMALLSQUAREWIDTH,SMALLSQUAREWIDTH,prevIcon,-1));
      buttons.add(new HomeButton(width/2-(SMALLSQUAREWIDTH*3/2),height/1.225,SMALLSQUAREWIDTH*3,SMALLSQUAREWIDTH,"HOME"));
    }
  }
}


void mousePressed() {  
  if (playState == State.PLAYING) { 
    // if i click in bounds (and not in the top area) 
    if (mouseY > TOPBARHEIGHT) {
      // http://www.java2s.com/Tutorial/Java/0140__Collections/TraversethroughArrayListinreversedirectionusingJavaListIterator.htm  
      // will delete most recently made balloon (the one on top)
      ListIterator<Balloon> iter = balloons.listIterator(balloons.size());
      while(iter.hasPrevious()) {
        Balloon balloon = iter.previous();
        if (balloon.isIn(mouseX,mouseY)) {
          // play the sound of the bubble popping!
          popSound.play();
          
          // add clicked letter to word
          currentWord += balloon.getLetter();
    
          // remove balloon and ignore any below
          iter.remove();
          return;
        }
      }
    }
  } else if (playState != State.PLAYING) {
    for (Button button : buttons) {
      if (button.isIn(mouseX,mouseY)) {
        button.clickedOn();
        return;
      }
    }
  }
}

void mouseMoved() {
  if (playState != State.PLAYING) {
    for (Button button : buttons) {
      button.setHovered(button.isIn(mouseX,mouseY));
    }
  }
}

void keyPressed() {
  if (playState == State.PLAYING) {
    if (key == ' ') {
      checkWord();
    }
  } 
  if (key == '1') {
    switchState(State.START);
  } else if (key == '2') {
    switchState(State.RULES);
  } else if (key == '3') {
    switchState(State.CREDITS);
  } else if (key == '4') {
    switchState(State.PLAYING);
  } else if (key == '5') {
    switchState(State.END);
  }
}