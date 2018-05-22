import processing.serial.*;

Serial shoePort;

Button [] buttons = new Button[4];

// Input storing strings
String fsr;
//String fsr = "BH818L817R818T819";
String[] fsrSplitted;
String[] healVal;
String[] leftVal;
String[] rightVal;
String[] toesVal;

// Input storing integers
int h, l, r, t, h0, l0, r0, t0 = 900;

SimonToneGenerator simonTones;

int [] simonSentence = new int[32]; // Length of the maximun sequence
int positionInSentence = 0;
int currentLengthOfTheSentence = 0;

int talkTime = 420;

int timeOut = 0;

boolean isSimonsTurn = true;

boolean isWrong = false;

void setup() {
  size(600,900);
  
  // Button:             Id/   X/   Y/Size/   Color
  buttons[0] = new Button(0, 150,   0, 300, #00ff00);  // Toes   Green
  buttons[1] = new Button(1, 300, 300, 300, #ff0000);  // Right  Red
  buttons[2] = new Button(2,   0, 300, 300, #ffff00);  // Left   Yellow
  buttons[3] = new Button(3, 150, 600, 300, #0000ff);  // Heel   Blue
  
  // Port:
  shoePort = new Serial(this, "COM6", 115200);
  //shoePort.write("m\r");
  //delay(8000);
  shoePort.write("p 1lrht\r");
  shoePort.write("F 0\r"); // Turn off FSR echo
  shoePort.clear();
  
  simonTones = new SimonToneGenerator(this);
  
  textSize(40);
  textAlign(CENTER, CENTER);
  
  simonStartsNewGame();
  
}

void draw() {
  
  simonTones.checkPlayTime();
  
  if(simonTones.isPlayingTone == false) setButtonLightsOff();
  
  if(isSimonsTurn) simonSays();
  //delay(100);
  //readShoe();
  
  // Display button lighted up
  displayButton();
  
  delay(50);
  readShoe();
  
  fill(255);
  
  if(isSimonsTurn) {
     if(currentLengthOfTheSentence == 0) text("Simon Starts", width/2, height/2); 
     else                                text("Simons Turn", width/2, height/2); 
  }
  else {
     text("Your Turn", width/2, height/2);
  }
  
}

void simonSays() {
  
  // After 1000 millisec
  if(millis() >= timeOut) {
  
    int simonsWord = simonSentence[positionInSentence];
    simonTones.playTone(simonsWord, talkTime);
    buttons[simonsWord].isLightOn = true;
    
    // Tacton Output
    if(simonsWord == 0) {
      shoePort.write("p 1r\r");  // Should be "p 1t\r"
      println("Simon: Toes");
    } 
    else if(simonsWord == 1) {
      shoePort.write("p 1l\r");  // Should be "p 1r\r"
      println("Simon: Right");
    } 
    else if(simonsWord == 2) {
      shoePort.write("p 1t\r");  // Should be "p 1l\r"
      println("Simon: Left");
    } 
    else {
      shoePort.write("p 1h\r");
      println("Simon: Heel"); 
    }
    
    if(positionInSentence < currentLengthOfTheSentence) {
      positionInSentence++;
    }
    else {
      isSimonsTurn = false;
      positionInSentence = 0;
    }
    
    //if(positionInSentence>=simonSentence.length) {
    //  positionInSentence = 0;    
    //}
    
    //println(positionInSentence);
    
    timeOut = millis() + talkTime + 55;
  }  
  
}


void tactonPressed(int tactonId) {
    
    if(isSimonsTurn == false) {
    
      for(Button currentButton : buttons) {
        if(currentButton.myId == tactonId) {
          
          currentButton.isLightOn = true;
          delay(50);
          currentButton.display();
          delay(50);
          // Incorrect
          if(simonSentence[positionInSentence] != currentButton.myId) {
            simonTones.playTone(4, 420);
            isWrong = true;
          }
          // Correct
          else {
            simonTones.playTone(currentButton.myId, 420);
          }
          delay(200);
        }
      }
      
      simonTones.stopTone();
      setButtonLightsOff();
      
      if(isWrong) {
        simonStartsNewGame();
        isWrong = false;
      }
      else {
        
        if(positionInSentence < currentLengthOfTheSentence) {
          positionInSentence++; 
          //println(positionInSentence);
        }
        else {
          
          if(currentLengthOfTheSentence == simonSentence.length-1) {
             println("user wins!!!"); 
             simonStartsNewGame();
          }
          else {
          
            currentLengthOfTheSentence++;
            
            if(currentLengthOfTheSentence <6)        talkTime = 420;
            else if(currentLengthOfTheSentence < 14) talkTime = 320;
            else                                     talkTime = 220;
            
            positionInSentence = 0;
            
            timeOut = millis() + 1000;
            isSimonsTurn = true;
          }
        }
        
      }
      
    }
    
}

void displayButton() {
  
  for(Button currentButton : buttons) {
    currentButton.display();
  }
  
}

void setButtonLightsOff() {
  
  for(Button currentButton : buttons) {
    currentButton.isLightOn = false;
  }  
  
}

void simonStartsNewGame() {
  
  makeNewSentence();
  timeOut = millis() + 1000;
  isSimonsTurn = true;
  
}

void makeNewSentence() {
  // Generate sequence
  for(int i = 0; i<simonSentence.length; i++) {
    simonSentence[i] = int(random(0,4));
  }
  
  positionInSentence = 0;
  currentLengthOfTheSentence = 0;
  
  //printArray(simonSentence);
  println(join(nf(simonSentence, 0), ", ")); // Print sequence at the start
}

void readShoe() {
  
  if(isSimonsTurn == false) {
    // Read FSR values
    shoePort.write("F 1\r"); // Turn on FSR echo
    shoePort.clear();
    delay(40);
    fsr = shoePort.readString();
    shoePort.write("F 0\r");
    
    // Isolate last line into 'fsr'
    fsrSplitted = splitTokens(fsr);
    fsr = fsrSplitted[fsrSplitted.length - 1];  // Last component of the array
    fsr += "E"; // Tag to indicate end of line
    //println();
    //println(fsr);
    
    // Isolate fsr value for each tacton
    healVal = match(fsr, "BH(.*?)L");
    h = Integer.parseInt(healVal[1]);
    leftVal = match(fsr, "L(.*?)R");
    l0 = l;
    l = Integer.parseInt(leftVal[1]);
    rightVal = match(fsr, "R(.*?)T");
    r = Integer.parseInt(rightVal[1]);
    toesVal = match(fsr, "T(.*?)E");
    t0 = t;
    t = Integer.parseInt(toesVal[1]);
    
    // Toes pressed
    if(t >= 550) {
      shoePort.write("p 1r\r"); // Should be "p 1t\r" (left foot code mistake)
      println("You: Toes");
      tactonPressed(0);
      delay(300);
    }
    // Right pressed  
    else if(r >= 750) {
      shoePort.write("p 1l\r"); // Should be "p 1r\r"
      println("You: Right");
      tactonPressed(1);
      delay(300);
    }
    // Left pressed
    else if(l >= 635) {
      shoePort.write("p 1t\r");  // Should be "p 1l\r"
      println("You: Left");
      tactonPressed(2);
      delay(300);
    }
    // Heal pressed  
    else if(h >= 695) {
      shoePort.write("p 1h\r");
      println("You: Heel");
      tactonPressed(3);
      delay(300);
    }
  }
  
}
