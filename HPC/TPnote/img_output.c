#include <stdio.h>
#include <stdlib.h>
#include "img_output.h"

void save_to_bmp(const char* filename, pixel_t* image, int width, int height) {
    FILE* f;
    int filesize = 54 + 3 * width * height;  // Taille du fichier BMP

    unsigned char bmpfileheader[14] = {
        'B','M',  // Signature
        0,0,0,0,  // Taille du fichier
        0,0,      // Réservé
        0,0,      // Réservé
        54,0,0,0  // Offset de début des données d'image
    };

    unsigned char bmpinfoheader[40] = {
        40,0,0,0,         // Taille de cette structure
        0,0,0,0,         // Largeur de l'image
        0,0,0,0,         // Hauteur de l'image
        1,0,             // Nombre de plans
        24,0,            // Bits par pixel
        0,0,0,0,         // Compression (aucune)
        0,0,0,0,         // Taille des données d'image (peut être 0 pour non compressé)
        0x13,0x0B,0,0,   // Résolution horizontale (pixels/mètre)
        0x13,0x0B,0,0,   // Résolution verticale (pixels/mètre)
        0,0,0,0,         // Nombre de couleurs dans la palette
        0,0,0,0          // Couleurs importantes
    };

    // Remplir la taille du fichier dans l'en-tête
    bmpfileheader[2] = (unsigned char)(filesize);
    bmpfileheader[3] = (unsigned char)(filesize >> 8);
    bmpfileheader[4] = (unsigned char)(filesize >> 16);
    bmpfileheader[5] = (unsigned char)(filesize >> 24);

    // Remplir la largeur et la hauteur dans l'en-tête d'information
    bmpinfoheader[4] = (unsigned char)(width);
    bmpinfoheader[5] = (unsigned char)(width >> 8);
    bmpinfoheader[6] = (unsigned char)(width >> 16);
    bmpinfoheader[7] = (unsigned char)(width >> 24);
    bmpinfoheader[8] = (unsigned char)(height);
    bmpinfoheader[9] = (unsigned char)(height >> 8);
    bmpinfoheader[10] = (unsigned char)(height >> 16);
    bmpinfoheader[11] = (unsigned char)(height >> 24);
    f = fopen(filename, "wb");
    if (!f) {
        printf("Erreur à l'ouverture du fichier %s\n", filename);
        return;
    }

    fwrite(bmpfileheader, sizeof(unsigned char), 14, f);
    fwrite(bmpinfoheader, sizeof(unsigned char), 40, f);
    fwrite(image, sizeof(pixel_t), width * height, f);
    fclose(f);
}