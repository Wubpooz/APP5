#ifndef IMG_OUTPUT_H
#define IMG_OUTPUT_H

typedef unsigned char pixel_t;

void save_to_bmp(const char* filename, pixel_t* image, int width, int height);

#endif // IMG_OUTPUT_H