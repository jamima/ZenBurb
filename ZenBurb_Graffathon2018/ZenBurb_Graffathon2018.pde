import moonlander.library.*;
import ddf.minim.*;

//Droplets
int CANVAS_WIDTH = 1920;
int CANVAS_HEIGHT = 1080;

int bpm = 120;
float bps = bpm/60;
int slices = 8;

float moon_counter_prev = 0; //Compare to this previous value 
int noiseCounterIndex = 4;
int dropletMax = 30; //How many droplets are drawn at max

JSONArray dropletArray;
int arrayIndex = 0; //Keep track of which droplet will be reset in the dropletArray
int new_droplet_r = 2;
float droplet_size_increment = 1;

float prev_time_stamp = 0;

Moonlander moonlander;

void settings() {
  size(CANVAS_WIDTH, CANVAS_HEIGHT, P2D);

}

void setup() {
  frameRate(60);
  moonlander = Moonlander.initWithSoundtrack(this, "Floating_Cities.mp3", bpm, slices);
  moonlander.start();
  colorMode(HSB, 360, 100, 100);
  background(240, 100, 0);
  noiseSeed(0);
  //noCursor(); //Todo enable for final version
  
  //Init Array and dropletData objects
  dropletArray = new JSONArray();
  for (int i = 0; i < dropletMax; i++) {
   //Init JSONobject 
   JSONObject dropletData = new JSONObject();
   dropletData.setFloat("x", 0);
   dropletData.setFloat("y", 0);
   dropletData.setFloat("r", 0);
   dropletArray.setJSONObject(i,dropletData);
  }
}

void draw() {
  background(0);
  moonlander.update();
  translate(width/2,height/2); //Start from somewhere
  float moon_counter = (float) moonlander.getValue("Floating_Cities");
  println(moon_counter, moon_counter_prev);
  
  if (moon_counter != moon_counter_prev) {
     // Time for new droplet!
     
     //Get location for new droplet
     float noiseValX = noise(noiseCounterIndex*33);
     float noiseValY = noise(noiseCounterIndex*100);
     
     float new_droplet_x = map(noiseValX, 0,1,-width/2, width/2); 
     float new_droplet_y = map(noiseValY, 0,1,-height/2, height/2); 

      //Overwrite JSONObject
      dropletArray.getJSONObject(arrayIndex).setFloat("x", new_droplet_x);
      dropletArray.getJSONObject(arrayIndex).setFloat("y", new_droplet_y);
      dropletArray.getJSONObject(arrayIndex).setFloat("r", new_droplet_r);
      arrayIndex++;
      if (arrayIndex >= dropletArray.size())
      {
         arrayIndex = 0;
      }
      moon_counter_prev = moon_counter;
  }

  //Draw droplets in array (remember to increase r)
  float current_time_stamp = (float) moonlander.getCurrentTime();
  for (int i = 0; i < dropletArray.size(); i++){
      float x = dropletArray.getJSONObject(i).getFloat("x");
      float y = dropletArray.getJSONObject(i).getFloat("y");
      float r = dropletArray.getJSONObject(i).getFloat("r");
      
      //println(current_time_stamp, prev_time_stamp);
      if (current_time_stamp > prev_time_stamp) {
        r = r + droplet_size_increment;
        dropletArray.getJSONObject(i).setFloat("r", r);
      }
      float intensity = 70 - droplet_size_increment * r;
      if (intensity > 0){
        fill(230,50,intensity);
        ellipse(x,y, r, r);
      }
  }
  prev_time_stamp = current_time_stamp;
  noiseCounterIndex++;
}

void circle(float x, float y, float size) {
    //Outer ellipse
  ellipseMode(CENTER);
  fill(255);
  ellipse(x, y, size, size);
  //Inner ellipse
  ellipseMode(CENTER); 
  fill(0);
   ellipse(x, y, size/1.2, size/1.2);

}
