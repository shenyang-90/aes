//============================================================================
// File: aes_types.sv
// Description: Common types and definitions for AES verification
//============================================================================

`ifndef AES_TYPES_SV
`define AES_TYPES_SV

// AES Modes
typedef enum bit [2:0] {
    AES_ECB = 3'b000,
    AES_CBC = 3'b001,
    AES_CTR = 3'b010,
    AES_GCM = 3'b011,
    AES_XTS = 3'b100,
    AES_CTS = 3'b101
} aes_mode_t;

// Key Lengths
typedef enum bit [1:0] {
    KEY_128 = 2'b00,
    KEY_192 = 2'b01,
    KEY_256 = 2'b10
} key_len_t;

// Register Addresses
parameter bit [11:0] REG_CTRL       = 12'h000;
parameter bit [11:0] REG_STATUS     = 12'h004;
parameter bit [11:0] REG_KEY_LEN    = 12'h008;
parameter bit [11:0] REG_MODE       = 12'h00C;
parameter bit [11:0] REG_KEY_0      = 12'h010;
parameter bit [11:0] REG_KEY_7      = 12'h02C;
parameter bit [11:0] REG_IV_0       = 12'h030;
parameter bit [11:0] REG_IV_3       = 12'h03C;
parameter bit [11:0] REG_CTS_EN     = 12'h040;
parameter bit [11:0] REG_SECTOR_ID  = 12'h044;
parameter bit [11:0] REG_INT_EN     = 12'h048;
parameter bit [11:0] REG_INT_STATUS = 12'h04C;

// Control register bits
parameter bit CTRL_START    = 0;
parameter bit CTRL_ENCRYPT  = 1;
parameter bit CTRL_MODE_0   = 4;
parameter bit CTRL_MODE_2   = 6;
parameter bit CTRL_CTS_EN   = 8;
parameter bit CTRL_INT_DONE = 16;

// NIST Test Vectors
typedef struct {
    string       name;
    key_len_t    key_len;
    bit [255:0]  key;
    bit [127:0]  plaintext;
    bit [127:0]  ciphertext;
    aes_mode_t   mode;
    bit [127:0]  iv;
} nist_vector_t;

`endif // AES_TYPES_SV
