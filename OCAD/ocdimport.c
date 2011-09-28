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
    
    f->data = calloc(s.st_size, sizeof(unsigned char));
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
    
    if (fread(f->data, sizeof(unsigned char), s.st_size, fp) != s.st_size) {
        fprintf(stderr, "Could not read all data.\n");
        fclose(fp);
        return 0;
    }
    
    f->header = (struct ocad_file_header *)(f->data);
    return 1;
}

void unload_file(struct ocad_file *f) {
    free(f->data);
    if (f->symbols != NULL) free(f->symbols);
    if (f->elements != NULL) free(f->elements);
    if (f->objects != NULL) free(f->objects);
    if (f->strings != NULL) {
        free(f->strings);
        free(f->string_rec_types);
    }
}

void load_symbols(struct ocad_file *f) {
    int k, j = 0;
    long i;
    struct ocad_symbol_block *b;
    
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
            f->symbols[j++] = (struct ocad_symbol *)((f->data) + b->symbol_indices[k]);
            f->symbols[j-1]->description[30] = 0;
        }
        i = b->nextsymbolblock;
    }
    b = (struct ocad_symbol_block *)((f->data) + f->header->symbolindex);
}

void load_objects(struct ocad_file *f) {
    int k, j = 0;
    long i;
    struct ocad_object_index_block *b;
    
    i = f->header->objectindex;
    while (i != 0) {
        b = (struct ocad_object_index_block *)((f->data) + i);
        
        for (k = 0; k < 256 && b->indices[k].position != 0; k++);
        
        j += k;
        i = b->nextindexblock;
    }
    f->num_objects = j;
    f->objects = calloc(sizeof(struct ocad_object_index *), f->num_objects);
    f->elements = calloc(sizeof(struct ocad_element *), f->num_objects);

    i = f->header->objectindex;
    j = 0;
    while (i != 0) {
        b = (struct ocad_object_index_block *)((f->data) + i);
        
        for (k = 0; k < 256 && b->indices[k].position != 0; k++) {
            f->objects[j + k] = &(b->indices[k]);
            f->elements[j + k] = (struct ocad_element *)((f->data) + (f->objects[j + k]->position));
            f->elements[j + k]->symbol = symbol_by_number(f, f->elements[j + k]->symnum);
        }
        
        j += k;
        i = b->nextindexblock;
    }
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

void get_bounding_box(struct ocad_file *ocdf, struct LRect *r) {
    int i;
    struct ocad_object_index *o;
    
    if (ocdf->num_objects < 1) {
        r->lower_left.x = 0;
        r->lower_left.y = 0;
        r->upper_right.x = 0;
        r->upper_right.y = 0;
        return;
    }
    
    r->lower_left.x = ocdf->objects[0]->rc.lower_left.x;
    r->lower_left.y = ocdf->objects[0]->rc.lower_left.y;
    r->upper_right.x = ocdf->objects[0]->rc.upper_right.x;
    r->upper_right.y = ocdf->objects[0]->rc.upper_right.y;
        
    for (i = 1; i < ocdf->num_objects; i++) {
        o = ocdf->objects[i];
        
        if (r->lower_left.x > o->rc.lower_left.x) r->lower_left.x = o->rc.lower_left.x;
        if (r->lower_left.y > o->rc.lower_left.y) r->lower_left.y = o->rc.lower_left.y;
        if (r->upper_right.x < o->rc.upper_right.x) r->upper_right.x = o->rc.upper_right.x;
        if (r->upper_right.y < o->rc.upper_right.y) r->upper_right.y = o->rc.upper_right.y;
    }

}
    
    
