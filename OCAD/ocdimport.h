//
//  ocdimport.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#include <stdio.h>
#include <stdint.h>

enum ocad_object_type {
    ocad_point_object = 1,
    ocad_line_object,
    ocad_area_object,
    ocad_unformatted_text_object,
    ocad_formatted_text_object,
    ocad_line_text_object,
    ocad_rectangle_object
};

struct TDPoly {
    int32_t x;
    int32_t y;
};

struct LRect {
    struct TDPoly lower_left;
    struct TDPoly upper_right;
};

struct ocad_symbol_element {
    int16_t symbol_type;
    uint16_t flags;
    int16_t color;
    int16_t line_width;
    int16_t diameter;
    int16_t ncoords;
    int16_t reserved1;
    int16_t reserved2;
    struct TDPoly points[0];
};

struct ocad_symbol {
    uint32_t size;
    uint32_t symnum;
    uint8_t  otp;
    uint8_t  flags;
    uint16_t selected;
    uint8_t status;
    uint8_t drawingtool;
    uint8_t csmode;
    uint8_t csobjtype;
    uint8_t cscdflags;
    uint32_t extent;
//    uint32_t filepos;
    uint16_t group;
    uint16_t ncolors;
    uint16_t colors[14];
    uint8_t desclength;
    char description[31];
    uint8_t iconbits[484]; // Kontrolldefinition.
};

struct ocad_point_symbol {
    // ocad_symbol
    uint32_t size;
    uint32_t symnum;
    uint8_t  otp;
    uint8_t  flags;
    uint16_t selected;
    uint8_t status;
    uint8_t drawingtool;
    uint8_t csmode;
    uint8_t csobjtype;
    uint8_t cscdflags;
    uint32_t extent;
    //    uint32_t filepos;
    uint16_t group;
    uint16_t ncolors;
    uint16_t colors[14];
    uint8_t desclength;
    char description[31];
    uint8_t iconbits[484]; // Kontrolldefinition.
    
    uint16_t datasize;
    uint16_t reserved;
    struct TDPoly points[256];
};

struct ocad_line_symbol {
    // ocad_symbol
    uint32_t size;
    uint32_t symnum;
    uint8_t  otp;
    uint8_t  flags;
    uint16_t selected;
    uint8_t status;
    uint8_t drawingtool;
    uint8_t csmode;
    uint8_t csobjtype;
    uint8_t cscdflags;
    uint32_t extent;
    //    uint32_t filepos;
    uint16_t group;
    uint16_t ncolors;
    uint16_t colors[14];
    uint8_t desclength;
    char description[31];
    uint8_t iconbits[484]; // Kontrolldefinition.
    
    // Line symbol
    uint16_t line_color;
    uint16_t line_width;
    uint16_t line_style;
    int16_t dist_from_start;
    int16_t dist_from_end;
    int16_t main_length;
    int16_t end_length;
    int16_t main_gap;
    int16_t sec_gap;
    int16_t end_gap;
    int16_t min_sym; // Minimum # gaps per symbol - 1.
    int16_t nprim_sym;
    int16_t prim_sym_dist;
    uint16_t dbl_mode;
    uint16_t dbl_flags;
    int16_t dbl_fill_color;
    int16_t dbl_left_color;
    int16_t dbl_right_color;
    int16_t dbl_width;
    int16_t dbl_left_width;
    int16_t dbl_right_width;
    int16_t dbl_length; // Dash distance a.
    int16_t dbl_gap; // Dash gap.
    int16_t reserved0;
    int16_t reserved1[2];
    uint16_t dec_mode;
    int16_t dec_last; // Last symbol.
    int16_t reserved2;
    int16_t frame_line_color;
    int16_t frame_line_width;
    int16_t frame_line_style;
    uint16_t prim_d_size;
    uint16_t sec_d_size;
    uint16_t corner_d_size;
    uint16_t start_d_size;
    uint16_t end_d_size;
    int16_t reserved3;
    struct TDPoly coords[1024];
};

struct ocad_area_symbol {
    // ocad_symbol
    uint32_t size;
    uint32_t symnum;
    uint8_t  otp;
    uint8_t  flags;
    uint16_t selected;
    uint8_t status;
    uint8_t drawingtool;
    uint8_t csmode;
    uint8_t csobjtype;
    uint8_t cscdflags;
    uint32_t extent;
    //    uint32_t filepos;
    uint16_t group;
    uint16_t ncolors;
    uint16_t colors[14];
    uint8_t desclength;
    char description[31];
    uint8_t iconbits[484]; // Kontrolldefinition.
    
    // Area symbol
    uint32_t border_symbol_number;
    int16_t fill_color;
    int16_t hatch_mode;
    int16_t hatch_color;
    int16_t hatch_line_width;
    int16_t hatch_dist;
    int16_t hatch_angle1;
    int16_t hatch_angle2;
    uint8_t fill_enabled;
    uint8_t border_enabled;
    uint16_t structure_mode;    //
    uint16_t structure_width;
    uint16_t structure_height;
    int16_t structure_angle;
    uint16_t reserved;
    uint16_t data_size;
    struct TDPoly coords[1024];
};

struct ocad_rectangle_symbol {
    // ocad_symbol
    uint32_t size;
    uint32_t symnum;
    uint8_t  otp;
    uint8_t  flags;
    uint16_t selected;
    uint8_t status;
    uint8_t drawingtool;
    uint8_t csmode;
    uint8_t csobjtype;
    uint8_t cscdflags;
    uint32_t extent;
    //    uint32_t filepos;
    uint16_t group;
    uint16_t ncolors;
    uint16_t colors[14];
    uint8_t desclength;
    char description[31];
    uint8_t iconbits[484]; // Kontrolldefinition.
    
    // Rectangle symbol
    int16_t line_color;
    int16_t line_width;
    uint16_t grid_flags;
    int16_t cell_width;
    int16_t cell_height;
    int16_t reserved0;
    int16_t reserved1;
    int16_t unnum_cells;
    int16_t unnum_text;
};

struct ocad_text_symbol {
    // ocad_symbol
    uint32_t size;
    uint32_t symnum;
    uint8_t  otp;
    uint8_t  flags;
    uint16_t selected;
    uint8_t status;
    uint8_t drawingtool;
    uint8_t csmode;
    uint8_t csobjtype;
    uint8_t cscdflags;
    uint32_t extent;
    //    uint32_t filepos;
    uint16_t group;
    uint16_t ncolors;
    uint16_t colors[14];
    uint8_t desclength;
    char description[31];
    uint8_t iconbits[484]; // Kontrolldefinition.
    
    uint8_t fontnamelength;
    char fontname[31];
    uint16_t fontcolor;
    uint16_t fontsize; // 10x the size in pt.
    int16_t weight; // 400: normal. 700: bold
    uint8_t italic;
    uint8_t character_set;
    int16_t charspacing;
    int16_t wordspacing;
    int16_t alignment;  // 0: bottom left
                        // 1: bottom center
                        // 2: bottom right
                        // 3: bottom justified
                        // 4: middle left
                        // 5: middle center
                        // 6: middle center
                        // 7: ?
                        // 8: top left
                        // 9: top center
                        // 10: top right
    int16_t linespacing;
    int16_t paraspacing;
    int16_t indent_first;
    int16_t indent_other;
    int16_t number_of_tabs;
    int32_t tabs[32];
    uint16_t underline;
    int16_t underline_color;
    int16_t underline_width;
    int16_t underline_distance;
    int16_t reserved3;
    uint8_t framing_mode;
    //   0: no framing
    //   1: shadow framing
    //   2: line framing
    //   3: rectangle framing
    uint8_t frame_line_style;
    uint16_t point_symbol_activated;
    int32_t point_symbol_num;
    uint8_t reserved2[19];
    int16_t frame_left;
    int16_t frame_bottom;
    int16_t frame_right;
    int16_t frame_top;
    int16_t frame_color;
    int16_t frame_width;
    int16_t frame_shadow_offset_x;
    int16_t frame_shadow_offset_y;
};

struct ocad_line_text_symbol {
    // ocad_symbol
    uint32_t size;
    uint32_t symnum;
    uint8_t  otp;
    uint8_t  flags;
    uint16_t selected;
    uint8_t status;
    uint8_t drawingtool;
    uint8_t csmode;
    uint8_t csobjtype;
    uint8_t cscdflags;
    uint32_t extent;
    //    uint32_t filepos;
    uint16_t group;
    uint16_t ncolors;
    uint16_t colors[14];
    uint8_t desclength;
    char description[31];
    uint8_t iconbits[484]; // Kontrolldefinition.
    
    uint8_t fontnamelength;
    char fontname[31];
    uint16_t fontcolor;
    uint16_t fontsize; // 10x the size in pt.
    int16_t weight; // 400: normal. 700: bold
    uint8_t italic;
    uint8_t character_set;
    int16_t charspacing;
    int16_t wordspacing;
    int16_t alignment;  // 0: bottom left
    // 1: bottom center
    // 2: bottom right
    // 3: bottom justified
    // 4: middle left
    // 5: middle center
    // 6: middle center
    // 7: ?
    // 8: top left
    // 9: top center
    // 10: top right
    uint8_t framing_mode;
    //   0: no framing
    //   1: shadow framing
    //   2: line framing
    //   3: rectangle framing
    uint8_t frame_line_style;
    uint8_t reserved2[32];
    int16_t frame_color;
    int16_t frame_width;
    int16_t frame_shadow_offset_x;
    int16_t frame_shadow_offset_y;
};

struct ocad_symbol_block {
    uint32_t nextsymbolblock;
    uint32_t symbol_indices[256];
};

struct ocad_string_index {
    uint32_t position;
    uint32_t len;
    int32_t rectype;
    uint32_t objectindex;
};

struct ocad_string_index_block {
    uint32_t nextindexblock;
    struct ocad_string_index indices[256];
};

struct ocad_object_index {
    struct LRect rc;
    uint32_t position;
    uint32_t length;
    int32_t symbol;
    uint8_t obj_type;
    uint8_t encrypted_mode;
    uint8_t status;
    uint8_t viewtype;    
    uint16_t color;
    uint16_t reserved1;
    uint16_t imported_layer;
    uint16_t reserved2;
};

struct ocad_element {
    int32_t symnum;
    uint8_t obj_type;
    uint8_t reserved0;
    int16_t angle;
    int32_t nCoordinates;
    int16_t nText;
    uint16_t reserved1;
    uint32_t color;
    uint16_t linewidth;
    uint16_t diamflags;
    
#if __LP64__
    struct ocad_symbol *symbol;
#else
    struct ocad_symbol *symbol;
    uint32_t dummy;
#endif
    uint8_t mark;
    uint8_t reserved3;
    uint16_t reserved4;
    uint32_t height;
    struct TDPoly coords[1];
};

struct ocad_object_index_block {
    uint32_t nextindexblock;
    struct ocad_object_index indices[256];
};


struct ocad_file_header {
    uint16_t ocadmark;
    uint8_t filetype;
    uint8_t status;
    uint16_t version;
    uint16_t subversion;
    uint32_t symbolindex;
    uint32_t objectindex;
    uint32_t reserved0;
    uint32_t reserved1;
    uint32_t reserved2;
    uint32_t reserved3;
    uint32_t stringindex;
    uint32_t filenamepos;
    uint32_t filenamesize;
    uint32_t reserved4;
};

struct ocad_file {
    unsigned char *data;
    struct ocad_file_header *header;
    
    int num_symbols;
    struct ocad_symbol **symbols;
    
    int num_objects;
    struct ocad_element **elements;
    struct ocad_object_index **objects;
    
    int num_strings;
    char **strings;
    int *string_rec_types;
};

// Functions
int load_file(struct ocad_file *f, const char *path);
void unload_file(struct ocad_file *f);
void load_symbols(struct ocad_file *f);
void load_objects(struct ocad_file *f);
void load_strings(struct ocad_file *f);

struct ocad_symbol *symbol_by_number(struct ocad_file *ocdf, int32_t symnum);
void get_bounding_box(struct ocad_file *ocdf, struct LRect *r);
