PImage img;

void setup()
{
//  img = loadImage("image.png");
  img = loadImage("pokemon.jpg");
//  img = loadImage("invite.jpg");
  size(img.width, img.height);
  noLoop();
  img.loadPixels();
  float[][][] rp = new float[img.width][img.height][2];
  float[][][] gp = new float[img.width][img.height][2];
  float[][][] bp = new float[img.width][img.height][2];
  for (int y = 0; y < img.height; ++y) {
    for (int x = 0; x < img.width; ++x) {
      color c = img.pixels[y * img.width + x];
      rp[y][x][0] = map(red(c), 0, 255, 0, 1);
      gp[y][x][0] = map(green(c), 0, 255, 0, 1);
      bp[y][x][0] = map(blue(c), 0, 255, 0, 1);
    }
  }
  rp = fft2d(rp);
  gp = fft2d(gp);
  bp = fft2d(bp);

  halfShift(rp);
  halfShift(gp);
  halfShift(bp);
  
//  reverse_gate(rp, 1);
//  reverse_gate(gp, 1);
//  reverse_gate(bp, 1);
  gate(rp, 1);
  gate(gp, 1);
  gate(bp, 1);
//  lowpass(rp, 40, 1);
//  lowpass(gp, 40, 1);
//  lowpass(bp, 40, 1);
//  highpass(rp, 40, 1);
//  highpass(gp, 40, 1);
//  highpass(bp, 40, 1);
//  bandpass(rp, 20, 25, .1);
//  bandpass(gp, 20, 25, .1);
//  bandpass(bp, 20, 25, .1);
//  
  halfShift(rp);
  halfShift(gp);
  halfShift(bp);
//  
  rp = inv_fft2d(rp);
  gp = inv_fft2d(gp);
  bp = inv_fft2d(bp);
  for (int y = 0; y < img.height; ++y) {
    for (int x = 0; x < img.width; ++x) {
//      int r = round(255 * log(1 + sqrt(rp[y][x][0] * rp[y][x][0] + rp[y][x][1] * rp[y][x][1])) / (log(512) + log(2) / 2));
//      int g = round(255 * log(1 + sqrt(gp[y][x][0] * gp[y][x][0] + gp[y][x][1] * gp[y][x][1])) / (log(512) + log(2) / 2));
//      int b = round(255 * log(1 + sqrt(bp[y][x][0] * bp[y][x][0] + bp[y][x][1] * bp[y][x][1])) / (log(512) + log(2) / 2));
      int r = round(map(sqrt(rp[y][x][0] * rp[y][x][0] + rp[y][x][1] * rp[y][x][1]), 0, 1, 0, 255));
      int g = round(map(sqrt(gp[y][x][0] * gp[y][x][0] + gp[y][x][1] * gp[y][x][1]), 0, 1, 0, 255));
      int b = round(map(sqrt(bp[y][x][0] * bp[y][x][0] + bp[y][x][1] * bp[y][x][1]), 0, 1, 0, 255));
      img.pixels[y * img.width + x] = color(r, g, b);
    }
  }
  img.updatePixels();
}

void draw()
{
  image(img, 0, 0);
}

float[][] fft(float[][] in)
{
  float[][] out = fft_helper(in);
//  int N = in.length;
//  float inv_sqrtN = 1.0 / sqrt(N);
//  for (int i = 0; i < N; ++i) {
//    out[i][0] *= inv_sqrtN;
//    out[i][1] *= inv_sqrtN;
//  }
  return out;
}

float[][] fft_helper(float[][] in)
{
  int N = in.length;
  int halfN = N / 2;
  float[][] out = new float[N][2];
  if (N == 1) {
    out[0][0] = in[0][0];
    out[0][1] = in[0][1];
    return out; 
  }
  float[][] a0 = new float[halfN][2];
  float[][] a1 = new float[halfN][2];
  for (int i = 0; i < N; i += 2) {
      a0[i/2][0] = in[i][0];
      a0[i/2][1] = in[i][1];
      a1[i/2][0] = in[i+1][0];
      a1[i/2][1] = in[i+1][1];
  }
  float[][] y0 = fft_helper(a0);
  float[][] y1 = fft_helper(a1);
  for (int k = 0; k < halfN; ++k) {
    float wr = cos((float)k * TAU / N);
    float wi = sin((float)k * TAU / N);
    out[k][0] = y0[k][0] + (wr * y1[k][0] - wi * y1[k][1]);
    out[k][1] = y0[k][1] + (wr * y1[k][1] + wi * y1[k][0]);
    out[k + halfN][0] = y0[k][0] - (wr * y1[k][0] - wi * y1[k][1]);
    out[k + halfN][1] = y0[k][1] - (wr * y1[k][1] + wi * y1[k][0]);
  }
  return out;
}

float[][] inv_fft(float[][] in)
{
  int N = in.length;
  float[][] out = inv_fft_helper(in);
  float invN = 1.0 / N;
//  float inv_sqrtN = 1.0 / sqrt(N);
  for (int i = 0; i < N; ++i) {
    out[i][0] *= invN;
    out[i][1] *= invN;
  }
  return out;
}

float[][] inv_fft_helper(float[][] in)
{
  int N = in.length;
  int halfN = N / 2;
  float[][] out = new float[N][2];
  if (N == 1) {
    out[0][0] = in[0][0];
    out[0][1] = in[0][1];
    return out; 
  }
  float[][] a0 = new float[halfN][2];
  float[][] a1 = new float[halfN][2];
  for (int i = 0; i < N; i += 2) {
      a0[i/2][0] = in[i][0];
      a0[i/2][1] = in[i][1];
      a1[i/2][0] = in[i+1][0];
      a1[i/2][1] = in[i+1][1];
  }
  float[][] y0 = inv_fft_helper(a0);
  float[][] y1 = inv_fft_helper(a1);
  for (int k = 0; k < halfN; ++k) {
    float wr = cos(-(float)k * TAU / N);
    float wi = sin(-(float)k * TAU / N);
    out[k][0] = y0[k][0] + (wr * y1[k][0] - wi * y1[k][1]);
    out[k][1] = y0[k][1] + (wr * y1[k][1] + wi * y1[k][0]);
    out[k + halfN][0] = y0[k][0] - (wr * y1[k][0] - wi * y1[k][1]);
    out[k + halfN][1] = y0[k][1] - (wr * y1[k][1] + wi * y1[k][0]);
  }
  return out;
}

float[][][] fft2d(float in[][][])
{
  float[][][] out = new float[in.length][in[0].length][2];
  float[][] row = new float[in[0].length][2];
  for (int y = 0; y < in.length; ++y) {
    for (int x = 0; x < row.length; ++x) {
      row[x][0] = in[y][x][0];
      row[x][1] = in[y][x][1];
    }
    row = fft(row);
    for (int x = 0; x < row.length; ++x) {
      out[y][x][0] = row[x][0];
      out[y][x][1] = row[x][1];
    }
  }
  float[][] col = new float[in.length][2];
  for (int x = 0; x < in[0].length; ++x) {
    for (int y = 0; y < row.length; ++y) {
      col[y][0] = out[y][x][0];
      col[y][1] = out[y][x][1];
    }
    col = fft(col);
    for (int y = 0; y < row.length; ++y) {
      out[y][x][0] = col[y][0];
      out[y][x][1] = col[y][1];
    }
  }
  return out;
}

float[][][] inv_fft2d(float in[][][])
{
  float[][][] out = new float[in.length][in[0].length][2];
  float[][] row = new float[in[0].length][2];
  for (int y = 0; y < in.length; ++y) {
    for (int x = 0; x < row.length; ++x) {
      row[x][0] = in[y][x][0];
      row[x][1] = in[y][x][1];
    }
    row = inv_fft(row);
    for (int x = 0; x < row.length; ++x) {
      out[y][x][0] = row[x][0];
      out[y][x][1] = row[x][1];
    }
  }
  float[][] col = new float[in.length][2];
  for (int x = 0; x < in[0].length; ++x) {
    for (int y = 0; y < row.length; ++y) {
      col[y][0] = out[y][x][0];
      col[y][1] = out[y][x][1];
    }
    col = inv_fft(col);
    for (int y = 0; y < row.length; ++y) {
      out[y][x][0] = col[y][0];
      out[y][x][1] = col[y][1];
    }
  }
  return out;
}

void halfShift(float[][][] data)
{
  int X = data[0].length;
  int Y = data.length;
  for (int y = 0; y < Y / 2; y++) {
    for (int x = 0; x < X; x++) {
      int xp = (x + X/2) % X;
      int yp = y + Y/2;
      float temp;
      temp = data[y][x][0];
      data[y][x][0] = data[yp][xp][0];
      data[yp][xp][0] = temp;
      temp = data[y][x][1];
      data[y][x][1] = data[yp][xp][1];
      data[yp][xp][1] = temp;
    }
  }
}

void bandpass(float[][][] data, float low, float high, float q) {
  lowpass(data, high, q);
  highpass(data, low, q);
}

void lowpass(float[][][] data, float threshold, float q) {
  int X = data[0].length;
  int Y = data.length;
  int Xc = X / 2;
  int Yc = Y / 2;
  float max = threshold * sqrt(1 + q);
  float min = threshold / (1 + q) ;
  for (int y = 0; y < Y; y++) {
    for (int x = 0; x < X; x++) {
      float d = sqrt((x - Xc) * (x - Xc) + (y - Yc) * (y - Yc));
      if (d < min) {
        continue;
      }
      if (d > max) {
        data[y][x][0] = 0;
        data[y][x][1] = 0;
        continue;
      }
      if (min == max) {
        continue;
      }
      float scale = cos(map(d, min, max, 0, PI / 2));
      scale *= scale;
      data[y][x][0] *= scale;
      data[y][x][1] *= scale;
    }
  }
}

void highpass(float[][][] data, float threshold, float q) {
  int X = data[0].length;
  int Y = data.length;
  int Xc = X / 2;
  int Yc = Y / 2;
  float max = threshold * sqrt(1 + q);
  float min = threshold / (1 + q) ;
  for (int y = 0; y < Y; y++) {
    for (int x = 0; x < X; x++) {
      float d = sqrt((x - Xc) * (x - Xc) + (y - Yc) * (y - Yc));
      if (d == 0) {
        continue;
      }
      if (d > max) {
        continue;
      }
      if (d < min) {
        data[y][x][0] = 0;
        data[y][x][1] = 0;
        continue;
      }
      if (min == max) {
        continue;
      }
      float scale = cos(map(d, min, max, PI / 2, 0));
      scale *= scale;
      data[y][x][0] *= scale;
      data[y][x][1] *= scale;
    }
  }
}

void gate(float[][][] data, float threshold)
{
  int X = data[0].length;
  int Y = data.length;
  float Xc = X / 2;
  float Yc = Y / 2;
  threshold = threshold * threshold;
  int suppressed_count = 0;
  for (int y = 0; y < Y; y++) {
    for (int x = 0; x < X; x++) {
      float d = (x - Xc) * (x - Xc) + (y - Yc) * (y - Yc);
      if ((data[y][x][0] * data[y][x][0] + data[y][x][1] * data[y][x][1]) / d < threshold) {
        data[y][x][0] = 0;
        data[y][x][1] = 0;
        ++suppressed_count;
      }
    }
  }
  println("" + suppressed_count + " frequencies removed (" + 100 * suppressed_count / (X * Y) + "% removed)");
}

void reverse_gate(float[][][] data, float threshold)
{
  int X = data[0].length;
  int Y = data.length;
  float Xc = X / 2;
  float Yc = Y / 2;
  threshold = threshold * threshold;
  int suppressed_count = 0;
  for (int y = 0; y < Y; y++) {
    for (int x = 0; x < X; x++) {
      float d = (x - Xc) * (x - Xc) + (y - Yc) * (y - Yc);
      if ((data[y][x][0] * data[y][x][0] + data[y][x][1] * data[y][x][1]) / d > threshold) {
        data[y][x][0] = 0;
        data[y][x][1] = 0;
        ++suppressed_count;
      }
    }
  }
  println("" + suppressed_count + " frequencies kept (" + 100 * suppressed_count / (X * Y) + "% kept)");
}
