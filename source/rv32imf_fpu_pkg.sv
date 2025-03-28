package rv32imf_fpu_pkg;

  
  
  

  
  parameter int unsigned NUM_FP_FORMATS = 5;
  
  parameter int unsigned FP_FORMAT_BITS = $clog2(NUM_FP_FORMATS);

  
  typedef enum logic [FP_FORMAT_BITS-1:0] {
    FP32    = 'd0,  
    FP64    = 'd1,  
    FP16    = 'd2,  
    FP8     = 'd3,  
    FP16ALT = 'd4   
  } fp_format_e;

  
  
  

  
  parameter int unsigned NUM_INT_FORMATS = 4;
  
  parameter int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    INT8,   
    INT16,  
    INT32,  
    INT64   
  } int_format_e;

  
  
  

  
  parameter int unsigned OP_BITS = 4;

  
  typedef enum logic [OP_BITS-1:0] {
    FMADD,     
    FNMSUB,    
    ADD,       
    MUL,       
    DIV,       
    SQRT,      
    SGNJ,      
    MINMAX,    
    CMP,       
    CLASSIFY,  
    F2F,       
    F2I,       
    I2F,       
    CPKAB,     
    CPKCD      
  } operation_e;

endpackage
