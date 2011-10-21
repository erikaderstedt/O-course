//
//  ocdimport.c
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#include "ocdimport.h"
#include "stdlib.h"
#include <sys/stat.h>
#include "string.h"

int supported_version(const char *path) {
    struct ocad_file_header *header;
    int s;
    FILE *fp;
    
    fp = fopen(path,"r");
    if (fp == NULL) {
        return 0;
    }

    header = calloc(1, sizeof(struct ocad_file_header));
    fread(header,1, sizeof(struct ocad_file_header), fp);
    fclose(fp);
    
    s = (header->version == 9 || header->version == 10);
    free(header);
    
    return s;
}

int load_file(struct ocad_file *f, const char *path) {
    /*
     Read the entire file into memory.
     */
    
    struct stat s;
    FILE *fp;
    
    if (stat(path, &s)) {
        fprintf(stderr, "Could not stat input file.\n");
        return 0;
    }
    
    f->data = calloc((unsigned long)s.st_size, sizeof(unsigned char));
    if (f->data == NULL) {
        fprintf(stderr, "Could not allocate memory.\n");
        return 0;
    }
    
    fp = fopen(path, "r");
    if (fp == NULL) {
        free(f->data);
        fprintf(stderr, "Could not open input file.\n");
        return 0;
    }
    
    if (fread(f->data, sizeof(unsigned char), (unsigned long)s.st_size, fp) != s.st_size) {
        fprintf(stderr, "Could not read all data.\n");
        fclose(fp);
        return 0;
    }
    
    f->header = (struct ocad_file_header *)(f->data);
    if (f->header->version == 8) {
        f->ocad8info = (struct ocad8_symbol_header *)(f->data + sizeof(struct ocad_file_header));
    } else {
        f->ocad8info = NULL;
    }
    return 1;
}

void unload_file(struct ocad_file *f) {
    free(f->data);
    if (f->symbols != NULL) {
        if (f->header->version == 8) {
            int i;
            for (i = 0; i < f->num_symbols; i++) {
                free(f->symbols[i]);
            }
        }
        free(f->symbols);
    }
    if (f->elements != NULL) {
        if (f->header->version == 8) {
            int i;
            for (i = 0; i < f->num_objects; i++) {
                free(f->elements[i]);
            }
        }
        free(f->elements);
    }
    if (f->strings != NULL) {
        free(f->strings);
        free(f->string_rec_types);
    }
}

void load_symbols(struct ocad_file *f) {
    int k, j = 0;
    long i;
    struct ocad_symbol_block *b;
    int version8 = (f->header->version == 8);
    
    i = f->header->symbolindex;
    
    while (i != 0) {
        b = (struct ocad_symbol_block *)((f->data) + i);
    
        for (k = 0; k < 256 && b->symbol_indices[k] != 0; k++);
        j += k;
        i = b->nextsymbolblock;
    }
    f->num_symbols = j;
    
    f->symbols = calloc(sizeof(struct ocad_symbol *), f->num_symbols);
    
    i = f->header->symbolindex;
    j = 0;
    while (j < f->num_symbols) {
        b = (struct ocad_symbol_block *)((f->data) + i);
        
        for (k = 0; k < 256 && j < f->num_symbols; k++) {
            if (version8) {
                f->symbols[j] = convert_ocad8_symbol((struct ocad8_symbol *)((f->data) + b->symbol_indices[k]));
            } else {
                f->symbols[j] = (struct ocad_symbol *)((f->data) + b->symbol_indices[k]);
            }
            f->symbols[j]->description[30] = 0;
            j++;
        }
        i = b->nextsymbolblock;
    }
    b = (struct ocad_symbol_block *)((f->data) + f->header->symbolindex);
}

void load_objects(struct ocad_file *f) {
    int k, j = 0;
    long i;
    struct ocad_object_index_block *b;
    struct ocad8_object_index_block *b8;
    struct ocad_element *element;
    struct LRect r;

    int version8 = (f->header->version == 8);
    
    i = f->header->objectindex;
    
    if (version8) {
        while (i != 0) {
            b8 = (struct ocad8_object_index_block *)((f->data) + i);
            
            for (k = 0; k < 256 && b8->indices[k].position != 0; k++);
            
            j += k;
            i = b8->nextindexblock;
        }        
    } else {
        while (i != 0) {
            b = (struct ocad_object_index_block *)((f->data) + i);
            
            for (k = 0; k < 256 && b->indices[k].position != 0; k++);
            
            j += k;
            i = b->nextindexblock;
        }
    }
    f->elements = calloc(sizeof(struct ocad_element *), j);
    
    i = f->header->objectindex;
    j = 0;
    
    r.lower_left.x = 1e30;
    r.lower_left.y = 1e30;
    r.upper_right.x = -1e30;
    r.upper_right.y = -1e30;
    
    if (version8) {
        while (i != 0) {
            b8 = (struct ocad8_object_index_block *)((f->data) + i);
            
            for (k = 0; k < 256 && b8->indices[k].position != 0; k++) {
                struct ocad8_object_index *objindex = &(b8->indices[k]);
                if (objindex->symnum == 0) continue;
                
                if (r.lower_left.x > objindex->rc.lower_left.x) r.lower_left.x = objindex->rc.lower_left.x;
                if (r.lower_left.y > objindex->rc.lower_left.y) r.lower_left.y = objindex->rc.lower_left.y;
                if (r.upper_right.x < objindex->rc.upper_right.x) r.upper_right.x = objindex->rc.upper_right.x;
                if (r.upper_right.y < objindex->rc.upper_right.y) r.upper_right.y = objindex->rc.upper_right.y;

                element = convert_ocad8_element((struct ocad8_element *)((f->data) + (objindex->position)));
                element->symbol = symbol_by_number(f, element->symnum);
                if (element->symbol != NULL) {
                    element->color = element->symbol->colors[0];
                } else {
                    element->color = 0;
                }
                f->elements[j++] = element;                
            }
            
            i = b8->nextindexblock;
        }
    } else {
        while (i != 0) {
            b = (struct ocad_object_index_block *)((f->data) + i);
            
            for (k = 0; k < 256 && b->indices[k].position != 0; k++) {
                struct ocad_object_index *objindex = &(b->indices[k]);
                if (objindex->status != 1) continue;
                
                element = (struct ocad_element *)((f->data) + (objindex->position));
                if (element->symnum == 0) {
                    element->obj_type = ocad_hidden_object;
                } else {
                    element->symbol = symbol_by_number(f, element->symnum);
                    if (element->symbol != NULL && element->symbol->selected != 512) {
                        if (r.lower_left.x > objindex->rc.lower_left.x) r.lower_left.x = objindex->rc.lower_left.x;
                        if (r.lower_left.y > objindex->rc.lower_left.y) r.lower_left.y = objindex->rc.lower_left.y;
                        if (r.upper_right.x < objindex->rc.upper_right.x) r.upper_right.x = objindex->rc.upper_right.x;
                        if (r.upper_right.y < objindex->rc.upper_right.y) r.upper_right.y = objindex->rc.upper_right.y;
                    }
                }

                f->elements[j++] = element;                
            }
            
            i = b->nextindexblock;
        }   
    }
    
    f->num_objects = j;
    f->bbox = r;
}

void load_strings(struct ocad_file *f) {
    int k,j = 0;
    long i;
    struct ocad_string_index_block *b;
    struct ocad_string_index *s;
    
    i = f->header->stringindex;
    while (i != 0) {
        b = (struct ocad_string_index_block *)((f->data) + i);
        
        for (k = 0; k < 256 && b->indices[k].position != 0; k++);
        
        j += k;
        i = b->nextindexblock;
    }
    f->num_strings = j;

    f->strings = calloc(sizeof(char *), f->num_strings);
    f->string_rec_types = calloc(sizeof(int), f->num_strings);
    i = f->header->stringindex;
    j = 0;
    int currentstring = 0;
    while (i != 0) {
        b = (struct ocad_string_index_block *)((f->data) + i);
        
        for (k = 0; k < 256 && b->indices[k].position != 0; k++) {
            s = &(b->indices[k]);
            f->string_rec_types[currentstring] = s->rectype;
            f->strings[currentstring] = (char *)(f->data + s->position);
            
            currentstring ++;
        }
        
        j += k;
        i = b->nextindexblock;
    }
    f->num_strings = currentstring;
   
}

struct ocad_symbol *symbol_by_number(struct ocad_file *ocdf, int32_t symnum) {
    int i;
    
    if (symnum < 0) return NULL;
    
    for (i = 0; i < ocdf->num_symbols && ocdf->symbols[i]->symnum != symnum; i++);
    
    if (i == ocdf->num_symbols) return NULL;
    
    return ocdf->symbols[i];
}

#define min(x,y) (((x)<(y))?(x):(y))

struct ocad_symbol *convert_ocad8_symbol(struct ocad8_symbol *source) {
    uint32_t newSize = source->size + sizeof(struct ocad_symbol) - sizeof(struct ocad8_symbol);
    struct ocad_symbol *dest;
    
    if ((dest = (struct ocad_symbol *)calloc(newSize, 1)) == NULL) return NULL;

    // Is this correct? 
    memcpy(&(dest[1]), &(source[1]), source->size - sizeof(struct ocad8_symbol));
    
    switch (source->otp) {
        case 1:
            dest->otp = ocad_point_object;
            break;
        case 2:
            if (source->symtype != 0) { 
                dest->otp = ocad_line_text_object;
            } else {
                dest->otp = ocad_line_object;
            }            
            break;
        case 3:
            dest->otp = ocad_area_object;
            ((struct ocad_area_symbol *)dest)->fill_enabled = ((struct ocad8_area_symbol *)source)->fill_on;
            ((struct ocad_area_symbol *)dest)->border_enabled = 0;
            break;
        case 4:
            dest->otp = ocad_formatted_text_object;
            ((struct ocad_text_symbol *)dest)->character_set ++; // 0 for OCAD 9, 1 for ASCII, 2 for "Unicode".
            break;
        default:
            dest->otp = 0;
            break;
    };
    
    // Base symbol
    dest->symnum = 100*source->symnum;
    dest->size = source->size;
    
    // Parse the color bitfield
    int j, k;
    dest->ncolors = 0;
    for (j = 0; j < 32; j++) {
        for (k = 0; k < 8; k++) {
            if (source->color_bitfield[j] & (1 << k)) {
                dest->colors[dest->ncolors] = j*8 + k;
                dest->ncolors ++;
            }
        }
    }
    
    // Copy the description
    dest->desclength = source->desclength;
    strncpy(dest->description, source->description, min(dest->desclength, 30));
    
    return dest;
}

struct ocad_element *convert_ocad8_element(struct ocad8_element *source) {
    struct ocad_element *dest;
    uint32_t newSize = (source->nCoordinates + source->nText - 1) * sizeof(struct TDPoly) + sizeof(struct ocad_element);
    
    if ((dest = (struct ocad_element *)calloc(newSize, 1)) == NULL) return NULL;
    
    dest->symnum = source->symnum * 100;
    dest->nCoordinates = source->nCoordinates;
    dest->nText = source->nText;
    dest->angle = source->angle;
    memcpy(&(dest->coords[0]), &(source->coords[0]), source->nCoordinates * sizeof(struct TDPoly));
    if (source->nText > 0) {
        memcpy(&(dest->coords[dest->nCoordinates]), &(source->coords[dest->nCoordinates]), dest->nText * sizeof(struct TDPoly));
    }
    
    switch (source->obj_type) {
        case 1:
            dest->obj_type = ocad_point_object;
            break;
        case 2:
            dest->obj_type = ocad_line_object;
            break;
        case 3:
            dest->obj_type = ocad_area_object;
            break;
        case 4:
            dest->obj_type = ocad_formatted_text_object;
            break;
        default:
            dest->obj_type = 0;
            break;
    };
    
    return dest;
}
