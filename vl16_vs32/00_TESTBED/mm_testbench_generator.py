import numpy as np
import os

def to_hex_string(int_array, width_bits):
    """
    Converts a numpy array of int8 into a single continuous bin string.
    """
    # Convert int8 to uint8 representation (0-255)
    uint_vals = int_array.astype(np.uint8)
    bin_str = ""
    for val in uint_vals:
        bin_str += format(val, '08b')
    return bin_str

def generate_all_configs():
    # ==========================================
    # Global Matrix Dimensions
    # ==========================================
    M = 512
    N = 512
    K = 256
    AD = 16
    
    # ==========================================
    # 1. Generate Consistent Matrices A and B
    # ==========================================
    print("Generating Master Matrices A and B...")
    # Matrix A: M x K
    MatrixA = np.random.randint(-128, 127, size=(M, K), dtype=np.int8)
    # Matrix B: K x N
    MatrixB = np.random.randint(-128, 127, size=(K, N), dtype=np.int8)
    
    # Compute Golden Matrix C: M x N (Accumulated as int32)
    MatrixC = np.matmul(MatrixA.astype(np.int32), MatrixB.astype(np.int32))

    # ==========================================
    # 2. Iterate through all VL / VS Configs
    # ==========================================
    VL_options = [8, 16, 32]
    VS_options = [16, 32, 64]

    for VL in VL_options:
        for VS in VS_options:
            config_name = f"vl{VL}_vs{VS}"
            print(f"Generating files for Config: {config_name} ...")
            os.makedirs(config_name)
            # ---------------------------------------------------------
            # Generate Input A File
            # Layout: Block-based. Outer loops M/VL, K/VS. Block size VL x VS.
            # ---------------------------------------------------------
            filename_a = f"{config_name}/inputA_int8.txt"
            with open(filename_a, "w") as fa:
                for m_blk in range(M // VL):
                    for k_blk in range(K // VS):
                        # Extract block (VL rows, VS cols)
                        block = MatrixA[m_blk*VL : (m_blk+1)*VL, k_blk*VS : (k_blk+1)*VS]
                        # Flatten row-major for the file line
                        flat_block = block.reshape(-1)
                        fa.write(to_hex_string(flat_block, VL*VS*8) + "\n")

            # ---------------------------------------------------------
            # Generate Input B File
            # Layout: Loop n(N/AD), ad(AD), k(K/VS). Vector size VS.
            # ---------------------------------------------------------
            filename_b = f"{config_name}/inputB_int8.txt"
            with open(filename_b, "w") as fb:
                for n_blk in range(N // AD):
                    for ad in range(AD):
                        for k_blk in range(K // VS):
                            # Extract Vector (VS rows, 1 col)
                            # B is K x N. 
                            # Row start: k_blk * VS
                            # Col index: n_blk * AD + ad
                            col_idx = n_blk * AD + ad
                            vec = MatrixB[k_blk*VS : (k_blk+1)*VS, col_idx]
                            fb.write(to_hex_string(vec, VS*8) + "\n")

            # ---------------------------------------------------------
            # Generate Golden Output File
            # Layout: Loop m(M/VL), n(N/AD). Inside: Block of size VL x AD.
            # Output writes one line per AD (depth), containing VL packed values.
            # ---------------------------------------------------------
            filename_g = f"{config_name}/golden_int8.txt"
            with open(filename_g, "w") as fg:
                for m_blk in range(M // VL):
                    for n_blk in range(N // AD):
                        # Extract Submatrix C_sub: VL rows x AD cols
                        # Rows: m_blk*VL : (m_blk+1)*VL
                        # Cols: n_blk*AD : (n_blk+1)*AD
                        C_sub = MatrixC[m_blk*VL : (m_blk+1)*VL, n_blk*AD : (n_blk+1)*AD]
                        
                        # Write AD lines
                        for y in range(AD):
                            line_bin = ""
                            # REVERSED ORDER: 0 to VL-1
                            # This places C_sub[0,y] at the "Left" (MSB side in string)
                            for x in range(0, VL, 1):
                                val = C_sub[x, y]
                                # Mask to 24 bits
                                line_bin += format(val & 0xFFFFFF, '024b')
                            fg.write(line_bin + "\n")

    print("All configurations generated successfully.")

if __name__ == "__main__":
    generate_all_configs()