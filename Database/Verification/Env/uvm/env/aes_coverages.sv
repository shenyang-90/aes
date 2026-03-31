//============================================================================
// Additional Covergroups for Coverage Improvement
// Description: Extended coverage collection for CTS, Fault, GCM, XTS
//============================================================================

`ifndef AES_COVERAGES_SV
`define AES_COVERAGES_SV

// Include in aes_env.sv

//----------------------------------------------------------------------------
// CTS Length Coverage (1-127 bit)
//----------------------------------------------------------------------------
covergroup cts_length_cg;
    option.name = "CTS Length Coverage";
    option.per_instance = 1;
    
    // All lengths from 1 to 127 bits
    cp_length: coverpoint cts_last_len {
        bins min_length = {1};           // 1 bit - minimum
        bins short[4] = {[2:31]};        // 2-31 bit (short data)
        bins medium[4] = {[32:63]};      // 32-63 bit (medium data)
        bins long[4] = {[64:95]};        // 64-95 bit (long data)
        bins near_full[4] = {[96:127]};  // 96-127 bit (near full block)
        bins max_length = {127};         // 127 bit - maximum stealing
        illegal_bins invalid = {0, [128:$]};  // 0 and >=128 are invalid
    }
    
    // Cross with encryption/decryption
    cp_encrypt: coverpoint encrypt;
    cross_length_op: cross cp_length, cp_encrypt;
endgroup

//----------------------------------------------------------------------------
// Fault Type Coverage
//----------------------------------------------------------------------------
covergroup fault_type_cg;
    option.name = "Fault Injection Type Coverage";
    option.per_instance = 1;
    
    cp_fault_type: coverpoint fault_type {
        bins clk_glitch_single = {0};    // Single cycle clock glitch
        bins clk_glitch_multi = {1};     // Multi-cycle clock glitch
        bins data_corrupt_bit = {2};     // Single bit corruption
        bins data_corrupt_byte = {3};    // Multi-bit/byte corruption
        bins key_corrupt = {4};          // Key corruption
        bins iv_corrupt = {5};           // IV corruption
    }
    
    cp_fault_target: coverpoint fault_target {
        bins plaintext = {0};
        bins ciphertext = {1};
        bins key_reg = {2};
        bins iv_reg = {3};
        bins internal_state = {4};
    }
    
    cp_detection: coverpoint fault_detected {
        bins detected = {1};
        bins not_detected = {0};
    }
    
    // Cross: fault type vs detection result
    cross_fault_detect: cross cp_fault_type, cp_detection;
endgroup

//----------------------------------------------------------------------------
// GCM AAD Coverage
//----------------------------------------------------------------------------
covergroup gcm_aad_cg;
    option.name = "GCM AAD Coverage";
    option.per_instance = 1;
    
    // AAD length coverage
    cp_aad_len: coverpoint aad_len {
        bins no_aad = {0};               // No AAD (auth only encryption)
        bins short_aad = {[1:128]};      // 1-128 bit (single block)
        bins medium_aad = {[129:512]};   // 129-512 bit (2-4 blocks)
        bins long_aad = {[513:1024]};    // 513-1024 bit (5-8 blocks)
        bins very_long_aad = {[1025:$]}; // >1024 bit (many blocks)
    }
    
    // CT length coverage
    cp_ct_len: coverpoint ct_len {
        bins short_ct = {[0:128]};
        bins medium_ct = {[129:512]};
        bins long_ct = {[513:1024]};
    }
    
    // AAD + CT cross
    cross_len: cross cp_aad_len, cp_ct_len;
    
    // Tag verification result
    cp_tag_valid: coverpoint tag_valid {
        bins valid = {1};
        bins invalid = {0};
    }
endgroup

//----------------------------------------------------------------------------
// XTS Sector Coverage
//----------------------------------------------------------------------------
covergroup xts_sector_cg;
    option.name = "XTS Sector Coverage";
    option.per_instance = 1;
    
    // Sector ID coverage - cover different patterns
    cp_sector_id_lsb: coverpoint sector_id[31:0] {
        bins sector_0 = {0};             // Sector 0
        bins sector_1 = {1};             // Sector 1
        bins sector_small = {[2:255]};   // Small sector numbers
        bins sector_medium = {[256:65535]};  // Medium sector numbers
        bins sector_large = {[65536:$]}; // Large sector numbers
    }
    
    // Block number within sector
    cp_block_num: coverpoint block_num {
        bins block_0 = {0};              // First block
        bins block_1 = {1};              // Second block
        bins block_small = {[2:15]};     // Blocks 2-15
        bins block_medium = {[16:255]};  // Blocks 16-255
        bins block_large = {[256:$]};    // Large block numbers
    }
    
    // Cross sector and block
    cross_sector_block: cross cp_sector_id_lsb, cp_block_num;
    
    // Encrypt/Decrypt
    cp_xts_encrypt: coverpoint xts_encrypt;
endgroup

//----------------------------------------------------------------------------
// Operation Cross Coverage (enhanced)
//----------------------------------------------------------------------------
covergroup operation_cross_cg;
    option.name = "AES Operation Cross Coverage";
    
    // All modes
    cp_mode: coverpoint aes_mode {
        bins ecb = {MODE_ECB};
        bins cbc = {MODE_CBC};
        bins ctr = {MODE_CTR};
        bins gcm = {MODE_GCM};
        bins xts = {MODE_XTS};
        bins cts = {MODE_CTS};
    }
    
    // All key lengths
    cp_key_len: coverpoint key_len {
        bins key_128 = {KEY_128};
        bins key_192 = {KEY_192};
        bins key_256 = {KEY_256};
    }
    
    // Encrypt/decrypt
    cp_encrypt: coverpoint encrypt;
    
    // Full cross coverage
    cross_full: cross cp_mode, cp_key_len, cp_encrypt {
        // Exclude invalid combinations
        ignore_bins ignore_invalid = cross_full with 
            (cp_mode == MODE_XTS && cp_key_len != KEY_128 && cp_key_len != KEY_256);
    }
endgroup

`endif // AES_COVERAGES_SV
