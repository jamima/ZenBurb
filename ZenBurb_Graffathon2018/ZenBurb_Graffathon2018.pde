//Music Floating Cities by Kevin MacLeod (incompetech.com)

import moonlander.library.*;
import ddf.minim.*;

//Droplets
int CANVAS_WIDTH = 1920;
int CANVAS_HEIGHT = 1080;

int bpm = 120;
float bps = bpm/60;
int slices = 8;

int noiseCounterIndexX = 45;
int noiseCounterIndexY = 65;

float static_start_time = 10;
float static_end_time = 8;
float slow_down_time = 2;

float movement_increment = CANVAS_HEIGHT * 0.001;

//Paw variables
float paw1_y = 0;
float paw2_y = 0;
float paw_to_paw_dist = CANVAS_WIDTH*0.1;
float paw_appearance_interval = 2; //Time difference between the two paws.
float paw_fade_time = 2; //How long a paw takes to fade
float paw_remain_time = paw_appearance_interval + paw_fade_time; //How long a paw is visible
float paw_loop_timer = 0; //This gives the running time from the start of paw loop (from cT - pLLT), reset to 0 when loop has been completed, due to pLLT = cT at that time
float paw_latest_loop_timestamp = static_start_time; // pLLT = cT when loop has been completed
float paw_intensity = 70;
float pawFadePercentage = 0;
float paws_appear_first_time = 8;

float prev_rocket_val = 0; //Compare to this previous value 
float rocket_val_diff = 0.048;
int noiseCounterIndex = 4;
int dropletMax = 80; //How many droplets are drawn at max

JSONArray dropletArray;
int arrayIndex = 0; //Keep track of which droplet will be reset in the dropletArray
float new_droplet_r = width*0.02;
float droplet_size_increment = width*0.01;
float droplet_mode_change_time = 30;

float end_time_s = 60;
float prev_time_stamp = 0;

float droplet_color_saturation = 50;
float intensity_threshold = 1;

Moonlander moonlander;

void settings() {
  size(CANVAS_WIDTH, CANVAS_HEIGHT, P2D);

}

void setup() {
  frameRate(60);
  moonlander = Moonlander.initWithSoundtrack(this, "data/Floating_Cities.mp3", bpm, slices);
  moonlander.start();
  colorMode(HSB, 360, 100, 100);
  background(240, 100, 0);
  noiseSeed(0);
  noStroke();
  noCursor(); 
  
  //Init Array and dropletData objects
  dropletArray = new JSONArray();
  for (int i = 0; i < dropletMax; i++) {
   //Init JSONobject 
   JSONObject dropletData = new JSONObject();
   dropletData.setFloat("x", 0);
   dropletData.setFloat("y", 0);
   dropletData.setFloat("r", 0);
   dropletData.setString("mode","full"); //full and empty
   dropletArray.setJSONObject(i,dropletData);
  }
}

void draw() {
  background(0);
  moonlander.update();
  translate(width/2,height/2); //Start from middle
  
  float current_time_stamp = (float) moonlander.getCurrentTime();
  if (current_time_stamp > end_time_s)
  {
    exit();
  }
  
  float curr_rocket_val = (float) moonlander.getValue("Floating_Cities");
  
  if (abs(curr_rocket_val - prev_rocket_val) > rocket_val_diff) {
     // Time for new droplet!
     
     //Get location for new droplet
     float noiseValX = noise(noiseCounterIndexX);
     float noiseValY = noise(noiseCounterIndexY);

     float new_droplet_x = map(noiseValX, 0.1,0.9,-width/2, width/2); 
     float new_droplet_y = map(noiseValY, 0.1,0.9,-height/2, height/2); 

      //Overwrite JSONObject in the JSONArray
      dropletArray.getJSONObject(arrayIndex).setFloat("x", new_droplet_x);
      dropletArray.getJSONObject(arrayIndex).setFloat("y", new_droplet_y);
      dropletArray.getJSONObject(arrayIndex).setFloat("r", new_droplet_r);
      assignDropletMode(current_time_stamp);
      arrayIndex++;
      if (arrayIndex >= dropletArray.size())
      {
         arrayIndex = 0;
      }
      
      //reset counter
      prev_rocket_val = curr_rocket_val;
  }
  
  //Draw droplets in array (remember to increase r)
  for (int i = 0; i < dropletArray.size(); i++){
      float x = dropletArray.getJSONObject(i).getFloat("x");
      float y = dropletArray.getJSONObject(i).getFloat("y");
      float r = dropletArray.getJSONObject(i).getFloat("r");
      String mode = dropletArray.getJSONObject(i).getString("mode");
      
      // println(current_time_stamp, prev_time_stamp);
      if (current_time_stamp > prev_time_stamp) {
        r = r + droplet_size_increment;
        dropletArray.getJSONObject(i).setFloat("r", r);
      }

      if (current_time_stamp >= static_start_time && current_time_stamp < (end_time_s - static_end_time)){
        if (current_time_stamp >= end_time_s - static_end_time - slow_down_time){
          movement_increment = movement_increment * (1 - (end_time_s - static_end_time - current_time_stamp) / slow_down_time);
        }
        y = y + movement_increment;
        dropletArray.getJSONObject(i).setFloat("y", y); 
      }
      
      drawRainDrop(x,y,r,mode);
  }
  
  // Drawing paws
  // Current loop time
  if (current_time_stamp < static_start_time && current_time_stamp > paws_appear_first_time){
     drawPaw(-paw_to_paw_dist/2, 0, width*0.05, 0);
     drawPaw(paw_to_paw_dist/2,0,width*0.05, 0);
  }
  else if (current_time_stamp >= (end_time_s - static_end_time)){
    paw_loop_timer = current_time_stamp - paw_latest_loop_timestamp;
    pawFadePercentage = paw_loop_timer / static_end_time;
    drawPaw(-paw_to_paw_dist/2, paw1_y + movement_increment, width*0.05, pawFadePercentage);
    drawPaw(paw_to_paw_dist/2, paw2_y + movement_increment, width*0.05, pawFadePercentage);
  }
  else{
    paw_loop_timer = current_time_stamp - paw_latest_loop_timestamp;
    if (paw_loop_timer >= 0.0 && paw_loop_timer < paw_fade_time) {
       pawFadePercentage = paw_loop_timer / paw_fade_time;       
       drawPaw(-paw_to_paw_dist/2, paw1_y, width*0.05, pawFadePercentage);
       paw1_y = paw1_y + movement_increment;
    }
    else if (paw_loop_timer >= paw_fade_time + paw_appearance_interval){
      drawPaw(-paw_to_paw_dist/2, paw1_y, width*0.05, 0);
      paw1_y = paw1_y + movement_increment;
    }
    else {
      paw1_y = 0;
    }
    pawFadePercentage = 0;
    if (paw_loop_timer >= 0.0 && paw_loop_timer < paw_fade_time + paw_appearance_interval) {
      drawPaw(paw_to_paw_dist/2, paw2_y, width*0.05, 0);
      paw2_y = paw2_y + movement_increment;
    }
    else if (paw_loop_timer >= paw_fade_time + paw_appearance_interval){
      pawFadePercentage = (paw_loop_timer - paw_fade_time - paw_appearance_interval)/paw_fade_time;
      drawPaw(paw_to_paw_dist/2, paw2_y,width*0.05, pawFadePercentage);
      paw2_y = paw2_y + movement_increment;
    }
    else {
     paw2_y = 0; 
    }
    
    if (paw_loop_timer >= paw_appearance_interval + paw_remain_time + paw_fade_time){
       paw_latest_loop_timestamp = current_time_stamp;
       paw2_y = 0;
    }
  }
  
  prev_time_stamp = current_time_stamp;
  noiseCounterIndexX++; noiseCounterIndexY++;
}

void drawRainDrop(float x, float y, float r) {
  // choose intensity for the droplet
  float intensity = 70 - droplet_size_increment * r;
  if (intensity > intensity_threshold){ // To remove black droplets
    fill(230, droplet_color_saturation, intensity);
    ellipse(x,y, r, r);
  }
}

void drawRainDrop(float x, float y, float r, String mode) {
  // choose intensity for the droplet
  float intensity = 70 - droplet_size_increment * r;
  if (intensity > intensity_threshold){ // To remove black droplets
    fill(230, droplet_color_saturation, intensity);
    if (mode == "empty")
    {
      circle(x,y, r);
    }
    else {
      ellipse(x,y, r, r);
    }
    
  }
}

void drawPaw(float centerX, float centerY, float pawSize, float pawFadePercentage) {
  //One big circle (using centerX and centerY), and 3 small circles
  if (pawFadePercentage < 1){ 
    fill(230, droplet_color_saturation, paw_intensity*(1-pawFadePercentage));
    
    //Big circle
    float pawFlatness = height*0.02;
    float toeDistance = width*0.01;
    float toeSize = width*0.015;
    float toeOffset = width*0.005;
    ellipse(centerX,centerY,pawSize,pawSize-pawFlatness);
    ellipse(centerX,centerY-(pawSize-pawFlatness)/2-toeDistance,toeSize, toeSize);
    ellipse(centerX-pawSize/2+toeOffset,centerY-(pawSize-pawFlatness)/2-toeDistance+toeOffset,toeSize, toeSize);
    ellipse(centerX+pawSize/2-toeOffset,centerY-(pawSize-pawFlatness)/2-toeDistance+toeOffset,toeSize, toeSize);
    
  }
}

void assignDropletMode(float current_time_stamp) {
  if ((current_time_stamp > droplet_mode_change_time && random(end_time_s-current_time_stamp) <= 10)) {
      dropletArray.getJSONObject(arrayIndex).setString("mode","empty");
  } else {
      dropletArray.getJSONObject(arrayIndex).setString("mode","full");
  }
}

void circle(float x, float y, float size) {
  //Outer ellipse
  ellipseMode(CENTER);
  //fill(255);
  ellipse(x, y, size, size);
  //Inner ellipse
  ellipseMode(CENTER); 
  fill(0);
   ellipse(x, y, size/1.1, size/1.1);

}
