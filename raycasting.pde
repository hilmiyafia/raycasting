
// Camera Parameters
float cameraX, cameraY;
float cameraVelocityX, cameraVelocityY;
float cameraForwardX, cameraForwardY;
float cameraRightX, cameraRightY;
float cameraMoveSpeed = 0.5;
float cameraTurnVelocity;
float cameraTurnSpeed = 5;
float cameraFov = 90;
float cameraNearPlane = 1;
float cameraFarPlane = 1000;
float cameraFogDistance = 100;
float cameraAngle;
float cameraLerp = 0.5;

// Input
boolean wPressed;
boolean aPressed;
boolean sPressed;
boolean dPressed;
boolean qPressed;
boolean ePressed;

// Render Parameters
PImage buffer;
int bufferWidth = 360, bufferHeight = 240;
int targetWidth = 1280, targetHeight = 720;
float halfTargetWidth = 640, halfTargetHeight = 360;

// Textures
PImage floorTexture;
PImage wallTexture;
PImage ceilingTexture;

// Walls
float wallHeight = 10;
Wall[] walls = {
  new Wall(-20, 10, 20, 10),
  new Wall(-20, -30, 50, -30),
  new Wall(-20, 10, -20, -30),
  new Wall(50, 50, 50, -30),
  new Wall(20, 10, 20, 50),
  new Wall(20, 50, 50, 50)
};

float epsilon = 0.001;

void setup() {
  size(1280, 720);
  frameRate(30);
  buffer = createImage(bufferWidth, bufferHeight, RGB);
  floorTexture = loadImage("floor.jpg");
  wallTexture = loadImage("wall.jpg");
  ceilingTexture = loadImage("ceiling.jpg");
}

void draw() {
  background(0);
  float cameraScreenX = cameraX + halfTargetWidth;
  float cameraScreenY = -cameraY + halfTargetHeight;
  float angle = radians(cameraAngle);
  cameraForwardX = cos(angle);
  cameraForwardY = sin(angle);
  cameraRightX = sin(angle);
  cameraRightY = -cos(angle);
  float deltaX = tan(radians(cameraFov / 2)) * cameraNearPlane;
  float deltaZ = bufferHeight * deltaX / bufferWidth;
  // Raycasting
  for (int i = 0; i < bufferWidth; i++) {
    float offset = (2 * i / float(bufferWidth) - 1) * deltaX;
    float vectorX = cameraForwardX * cameraNearPlane + cameraRightX * offset;
    float vectorY = cameraForwardY * cameraNearPlane + cameraRightY * offset;
    float magnitude2D = sqrt(vectorX * vectorX + vectorY * vectorY);
    float directionX = vectorX / magnitude2D;
    float directionY = vectorY / magnitude2D;
    RaycastResult result = raycast(directionX, directionY);
    float depth = directionX * result.distance * cameraForwardX + directionY * result.distance * cameraForwardY;
    float wallScreenHeight = wallHeight * (cameraNearPlane / depth) * (bufferHeight / deltaZ);
    int wallStart = int(clamp(0.5 * bufferHeight - 0.25 * wallScreenHeight, 0, 0.5 * bufferHeight));
    int wallStop = bufferHeight - wallStart;
    float wallOffset = 0.25 - 0.5 * (wallStart + wallStop) / wallScreenHeight;
    // Draw Ceilings
    for (int j = 0; j < wallStart; j++)
    {
      float vectorZ = (1 - 2 * j / float(bufferHeight)) * deltaZ;
      float magnitude3D = sqrt(magnitude2D * magnitude2D + vectorZ * vectorZ);
      float directionZ = vectorZ / magnitude3D;
      if (directionZ < epsilon && directionZ > -epsilon) { 
        buffer.pixels[i + j * bufferWidth] = color(0);
        continue;
      }
      float distance = (wallHeight / 2) / directionZ;
      float u = cameraX + vectorX * distance / magnitude3D;
      float v = cameraY + vectorY * distance / magnitude3D;
      if (u < 0) u = 1 - (-u % wallHeight) / wallHeight; else u = (u % wallHeight) / wallHeight;
      if (v < 0) v = 1 - (-v % wallHeight) / wallHeight; else v = (v % wallHeight) / wallHeight;
      color albedo = ceilingTexture.get(int(clamp(u, 0, 1) * (ceilingTexture.width - 1)), int(clamp(v, 0, 1) * (ceilingTexture.height - 1)));
      float shade = clamp((1 - (distance - cameraNearPlane) / (cameraFogDistance - cameraNearPlane)), 0, 1);
      buffer.pixels[i + j * bufferWidth] = multiplyColor(albedo, shade);
    }
    // Draw Walls
    for (int j = wallStart; j < wallStop; j++)
    {
      float v = j / wallScreenHeight + wallOffset;
      float y = 0.5 * wallHeight * (1 - 2 * v);
      float distance = sqrt(y * y + result.distance * result.distance);
      color albedo = wallTexture.get(int(clamp(result.u, 0, 1) * (wallTexture.width - 1)), int(clamp(v, 0, 1) * (wallTexture.height - 1)));
      float shade = clamp(1 - (distance - cameraNearPlane) / (cameraFogDistance - cameraNearPlane), 0, 1);
      buffer.pixels[i + j * bufferWidth] = multiplyColor(albedo, shade);
    }
    // Draw Floors
    for (int j = wallStop; j < bufferHeight; j++)
    {
      float vectorZ = (1 - 2 * j / float(bufferHeight)) * deltaZ;
      float magnitude3D = sqrt(magnitude2D * magnitude2D + vectorZ * vectorZ);
      float directionZ = vectorZ / magnitude3D;
      if (directionZ < epsilon && directionZ > -epsilon) {
        buffer.pixels[i + j * bufferWidth] = color(0);
        continue;
      }
      float distance = (-wallHeight / 2) / directionZ;
      float u = cameraX + vectorX * distance / magnitude3D;
      float v = cameraY + vectorY * distance / magnitude3D;
      if (u < 0) u = 1 - (-u % wallHeight) / wallHeight; else u = (u % wallHeight) / wallHeight;
      if (v < 0) v = 1 - (-v % wallHeight) / wallHeight; else v = (v % wallHeight) / wallHeight;
      color albedo = floorTexture.get(int(clamp(u, 0, 1) * (floorTexture.width - 1)), int(clamp(v, 0, 1) * (floorTexture.height - 1)));
      float shade = clamp((1 - (distance - cameraNearPlane) / (cameraFogDistance - cameraNearPlane)), 0, 1);
      buffer.pixels[i + j * bufferWidth] = multiplyColor(albedo, shade);
    }
  }
  buffer.updatePixels();
  image(buffer, 0, 0, targetWidth, targetHeight);
  // Draw Camera Direction
  stroke(255);
  line(cameraScreenX, cameraScreenY, cameraScreenX + cameraForwardX * 10, cameraScreenY - cameraForwardY * 10);
  // Draw Camera Position
  noStroke();
  fill(255, 0, 0);
  ellipse(cameraX + halfTargetWidth, -cameraY + halfTargetHeight, 10, 10);
  // Draw Walls
  stroke(0, 255, 0);
  for (int i = 0; i < walls.length; i++) {
    line(
       walls[i].p1X + halfTargetWidth, 
      -walls[i].p1Y + halfTargetHeight, 
       walls[i].p2X + halfTargetWidth, 
      -walls[i].p2Y + halfTargetHeight
    );
  }
  // Update Input
  float velocityX = 0;
  float velocityY = 0;
  float velocityZ = 0;
  if (aPressed) {
    velocityX -= cameraRightX * cameraMoveSpeed;
    velocityY -= cameraRightY * cameraMoveSpeed;
  }
  if (dPressed) {
    velocityX += cameraRightX * cameraMoveSpeed;
    velocityY += cameraRightY * cameraMoveSpeed;
  }
  if (wPressed) {
    velocityX += cameraForwardX * cameraMoveSpeed;
    velocityY += cameraForwardY * cameraMoveSpeed;
  }
  if (sPressed) {
    velocityX -= cameraForwardX * cameraMoveSpeed;
    velocityY -= cameraForwardY * cameraMoveSpeed;
  }
  if (qPressed) velocityZ += cameraTurnSpeed;
  if (ePressed) velocityZ -= cameraTurnSpeed;
  // Update Camera
  cameraVelocityX = cameraLerp * velocityX + (1 - cameraLerp) * cameraVelocityX;
  cameraVelocityY = cameraLerp * velocityY + (1 - cameraLerp) * cameraVelocityY;
  cameraX += cameraVelocityX;
  cameraY += cameraVelocityY;
  cameraTurnVelocity = cameraLerp * velocityZ + (1 - cameraLerp) * cameraTurnVelocity;
  cameraAngle += cameraTurnVelocity;
}

color multiplyColor(color col, float a) {
  return color(red(col) * a, green(col) * a, blue(col) * a);
}

void keyPressed() {
  if (key == 'w') wPressed = true;
  if (key == 'a') aPressed = true;
  if (key == 's') sPressed = true;
  if (key == 'd') dPressed = true;
  if (key == 'q') qPressed = true;
  if (key == 'e') ePressed = true;
}

void keyReleased()
{
  if (key == 'w') wPressed = false;
  if (key == 'a') aPressed = false;
  if (key == 's') sPressed = false;
  if (key == 'd') dPressed = false;
  if (key == 'q') qPressed = false;
  if (key == 'e') ePressed = false;
}

int clamp(int x, int min, int max) {
  if (x < min) return min;
  if (x > max) return max;
  return x;
}

float clamp(float x, float min, float max) {
  if (x < min) return min;
  if (x > max) return max;
  return x;
}

RaycastResult raycast(float directionX, float directionY) {
  RaycastResult result = new RaycastResult();
  for (int i = 0; i < walls.length; i++) {
    float determinant = directionX * walls[i].dY - directionY * walls[i].dX;
    if (determinant < epsilon && determinant > -epsilon)
      continue;
    float distance = walls[i].dY * (walls[i].p1X - cameraX) - walls[i].dX * (walls[i].p1Y - cameraY);
    distance /= determinant;
    if (distance < cameraNearPlane || distance > result.distance)
      continue;
    float u = directionY * (cameraX - walls[i].p1X) - directionX * (cameraY - walls[i].p1Y);
    u /= determinant;
    if (u < 0 || u > 1)
      continue;
    result.distance = distance;
    result.u = ((u * walls[i].wallLength) % wallHeight) / wallHeight;
  }
  return result;
}

class RaycastResult {
  float distance = cameraFarPlane;
  float u;
  RaycastResult() {
  }
}   

class Wall {
  float p1X, p1Y;
  float p2X, p2Y;
  float  dX,  dY;
  float wallLength;
  Wall(float pAX, float pAY, float pBX, float pBY) {
    p1X = pAX;
    p1Y = pAY;
    p2X = pBX;
    p2Y = pBY;
    dX  = p1X - p2X;
    dY  = p1Y - p2Y;
    wallLength = sqrt(dX * dX + dY * dY);
  }
}
