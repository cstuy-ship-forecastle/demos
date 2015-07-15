import processing.video.*;

final int CAMX = 640;
final int CAMY = 480;
final int PROJX = 640;
final int PROJY = 480;

PImage orig;
PImage rect;

Capture cam;
  
float[][] rectangle = {
  {0, PROJY},
  {PROJX, PROJY},
  {PROJX, 0},
  {0, 0}
};

float[][] mapping;

void update_mapping()
{
  mapping =
//      matrix_inverse(
      projective_map(0, height, PROJX, height, PROJX, 0, 0, 0,
      rectangle[0][0], rectangle[0][1], rectangle[1][0], rectangle[1][1], rectangle[2][0], rectangle[2][1], rectangle[3][0], rectangle[3][1])
//      )
      ; 
}

void setup()
{
  size(2 * PROJX, PROJY);
  orig = createImage(CAMX, CAMY, RGB);
  rect = createImage(PROJX, PROJY, RGB);
  cam = new Capture(this, CAMX, CAMY);
  update_mapping();
  cam.start();  
}

void draw()
{
  if (cam.available() == true) {
    cam.read();
  }
  orig.set(0, 0, cam);
  orig.resize(PROJX, PROJY);
  
  orig.loadPixels();
  for (int r = 0; r < rect.height; ++r) {
    for (int c = 0; c < rect.width; ++c) {
      
      float[][] p = {{c, r, 1}};
      float[] transformed_p = matrix_column(matrix_multiply(mapping, p), 0);
      int sample_c = round(transformed_p[0] / transformed_p[2]);
      int sample_r = round(transformed_p[1] / transformed_p[2]);
      if (sample_c < 0) {
        sample_c = orig.width - (1 + (- 1 - sample_c) % orig.width);
      } else {
        sample_c = sample_c % orig.width;
      }
      if (sample_r < 0) {
        sample_r = orig.height - (1 + (- 1 - sample_r) % orig.height);
      } else {
        sample_r = sample_r % orig.height;
      }
      
      if (sample_c < 0 || sample_c > orig.width - 1 || sample_r < 0 || sample_r > orig.height - 1) {
        println("(" + sample_c + ", " + sample_r + ")");
      }
      rect.pixels[r * rect.width + c] = orig.pixels[sample_r * orig.width + sample_c];
    }
  }
  rect.updatePixels();
  
  image(orig, 0, 0);
  image(rect, orig.width, 0);
  for (int i = 0; i < rectangle.length; ++i) {
    int j = (i + 1) % rectangle.length;
    line (rectangle[i][0], rectangle[i][1], rectangle[j][0], rectangle[j][1]);
  }
}

int selected_point = 0;

void mousePressed() {
  int min_point = -1;
  float min_distance = 0;
  for (int i = 0; i < rectangle.length; ++i) {
    float distance = (rectangle[i][0] - mouseX) * (rectangle[i][0] - mouseX) + (rectangle[i][1] - mouseY) * (rectangle[i][1] - mouseY);
    if (min_point == -1 || distance < min_distance) {
      min_point = i;
      min_distance = distance;
    }
  }
  selected_point = min_point;
}

void mouseDragged() {
  rectangle[selected_point][0] = mouseX;
  rectangle[selected_point][1] = mouseY;
  update_mapping();
}

float dot_product(float[] a, float[] b)
{
  if (a.length != b.length) {
    println("ERROR: multipling incompatibly sized vectors");
    exit();
  }
  float product = 0;
  for (int i = 0; i < a.length; ++i) {
    product += a[i] * b[i];
  }
  return product;
}

/* returns a copy of a particular column from a matrix */
float[] matrix_column(float[][] m, int column_index)
{
  int column_size = m[0].length;
  float[] column = new float[column_size];
  for (int i = 0; i < column_size; ++i) {
    column[i] = m[column_index][i];
  }
  return column;
}

/* returns a copy of a particular row from a matrix */
float[] matrix_row(float[][] m, int row_index)
{
  int row_size = m.length;
  float[] row = new float[row_size];
  for (int i = 0; i < row_size; ++i) {
    row[i] = m[i][row_index];
  }
  return row;
}

float[][] matrix_multiply(float[][] a, float[][] b)
{
  if (a.length != b[0].length) {
    println("ERROR: multipling incompatibly sized matricies");
    exit();
  }
  float[][] product = new float[b.length][a[0].length];
  for (int column = 0; column < product.length; ++column) {
    for (int row = 0; row < product[0].length; ++row) {
      product[column][row] = dot_product(matrix_row(a, row), matrix_column(b, column));
    }
  }
  return product;
}

// Flips a matrix along its main diagonal
float[][] matrix_transpose(float[][] m)
{
  float[][] transpose = new float[m[0].length][m.length];
  for (int i = 0; i < transpose.length; ++i) {
    for (int j = 0; j < transpose[0].length; ++j) {
      transpose[i][j] = m[j][i];
    }
  }
  return transpose;
}

/* returns a copy of a matrix with a specified column and row removed */
float[][] matrix_remove(float[][] m, int removed_column, int removed_row)
{
  float[][] result = new float[m.length - 1][m[0].length - 1];
  for (int column = 0; column < result.length; ++column) {
    for (int row = 0; row < result[0].length; ++row) {
      int source_column = column;
      if (source_column >= removed_column) {
        ++source_column;
      }
      int source_row = row;
      if (source_row >= removed_row) {
        ++source_row;
      }
      result[column][row] = m[source_column][source_row];
    }
  }
  return result;
}

float matrix_determinant(float[][] m) {
  if (m.length != m[0].length) {
    println("ERROR: cannot take determinant of non-square matrix");
  }
  if (m.length == 1) {
    return m[0][0];
  }
  float determinant = 0;
  for (int i = 0; i < m[0].length; ++i) {
    determinant += (i % 2 == 0 ? 1 : -1) * m[0][i] * matrix_determinant(matrix_remove(m, 0, i));
  }
  return determinant;
}

/* creates and returns the cofactor matrix for a given matrix */
float[][] matrix_cofactor(float[][] m) {
  if (m.length != m[0].length) {
    println("ERROR: cannot get cofactor of non-square matrix");
  }
  float[][] cofactor = new float[m.length][m[0].length];
  for (int i = 0; i < cofactor.length; ++i) {
    for (int j = 0; j < cofactor[0].length; ++j) {
      cofactor[i][j] = ((i + j) % 2 == 0 ? 1 : -1) * matrix_determinant(matrix_remove(m, i, j));
    }
  }
  return cofactor;
}

float[][] matrix_scale(float[][] m, float s) {
  float[][] scaled_m = new float[m.length][m[0].length];
  for (int i = 0; i < scaled_m.length; ++i) {
    for (int j = 0; j < scaled_m[0].length; ++j) {
      scaled_m[i][j] = s * m[i][j];
    }
  }
  return scaled_m;
}

float[][] matrix_inverse(float[][] m) {
  if (m.length != m[0].length) {
    println("ERROR: cannot invert on-square matrix");
  }
  float[][] cofactor_transpose = matrix_transpose(matrix_cofactor(m));
  float determinant = dot_product(matrix_row(m, 0), matrix_column(cofactor_transpose, 0)); // this is the determinant of m
  return matrix_scale(cofactor_transpose, 1.0 / determinant);
}

// creates a matrix that maps from (1, 0, 0) -> a, (0, 1, 0) -> b, (0, 0, 1) -> c, and (1, 1, 1) -> d;
float[][] half_projective_map(float ax, float ay, float bx, float by, float cx, float cy, float dx, float dy)
{
  float[][] m = {
    {ax, ay, 1},
    {bx, by, 1},
    {cx, cy, 1}
  };
  float[][] d = {{dx, dy, 1}};
  float[][] m_inv = matrix_inverse(m);
  float[] scalers = matrix_column(matrix_multiply(m_inv, d), 0);
  float[][] s = {
    {scalers[0], 0, 0},
    {0, scalers[1], 0},
    {0, 0, scalers[2]}
  };
  return matrix_multiply(m, s);
}

float[][] projective_map(float ax0, float ay0, float bx0, float by0, float cx0, float cy0, float dx0, float dy0,
    float ax, float ay, float bx, float by, float cx, float cy, float dx, float dy) {
  float[][] q1 = half_projective_map(ax0, ay0, bx0, by0, cx0, cy0, dx0, dy0);
  float[][] q2 = half_projective_map(ax, ay, bx, by, cx, cy, dx, dy);
  return matrix_multiply(q2, matrix_inverse(q1));
}
