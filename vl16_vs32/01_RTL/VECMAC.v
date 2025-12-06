module VECMAC #(
    parameter VS = 32,
    parameter SUM_W = 24,
    parameter N_LVL = $clog2(VS)
)(
    input           [VS*8-1:0]  i_vec_a,
    input           [VS*8-1:0]  i_vec_b,
    input   signed  [SUM_W-1:0] i_partial_sum_in,
    output  signed  [SUM_W-1:0] o_partial_sum_out
);

reg  signed [7:0]       mult8_in1[VS-1:0], mult8_in2[VS-1:0];
reg  signed [15:0]      mult8_out[VS-1:0];
wire signed [20:0]      add8_final_in1;
reg  signed [SUM_W-1:0] add8_final_in2;
reg  signed [SUM_W:0]   add8_final_out;
integer                 i;

assign o_partial_sum_out = add8_final_out[SUM_W-1:0];

always @(*) begin
    for (i = 0; i < VS; i = i + 1) begin
        mult8_in1[i] = $signed({i_vec_a[8*i +: 8]});
        mult8_in2[i] = $signed({i_vec_b[8*i +: 8]});
        mult8_out[i] = mult8_in1[i] * mult8_in2[i];
    end
end

genvar lvl_i;
generate
for (lvl_i = 0; lvl_i < N_LVL; lvl_i = lvl_i + 1) begin : gen_add_levels
    wire signed [16+lvl_i-1:0]  add8_in1[VS/(2**(lvl_i+1))-1:0];
    wire signed [16+lvl_i-1:0]  add8_in2[VS/(2**(lvl_i+1))-1:0];
    wire signed [16+lvl_i:0]    add8_out[VS/(2**(lvl_i+1))-1:0];
    genvar                      j;
    if (lvl_i == 0) begin
        for (j = 0; j < VS/(2**(lvl_i+1)); j = j + 1) begin
            assign add8_in1[j] = mult8_out[2*j];
            assign add8_in2[j] = mult8_out[2*j+1];
            assign add8_out[j] = add8_in1[j] + add8_in2[j];
        end 
    end
    else if (lvl_i == N_LVL-1) begin
        for (j = 0; j < VS/(2**(lvl_i+1)); j = j + 1) begin
            assign add8_in1[j] = gen_add_levels[lvl_i-1].add8_out[2*j];
            assign add8_in2[j] = gen_add_levels[lvl_i-1].add8_out[2*j+1];
            assign add8_final_in1 = add8_in1[j] + add8_in2[j];
        end
    end
    else begin
        for (j = 0; j < VS/(2**(lvl_i+1)); j = j + 1) begin
            assign add8_in1[j] = gen_add_levels[lvl_i-1].add8_out[2*j];
            assign add8_in2[j] = gen_add_levels[lvl_i-1].add8_out[2*j+1];
            assign add8_out[j] = add8_in1[j] + add8_in2[j];
        end
    end
end
endgenerate

always @(*) begin
    add8_final_in2 = i_partial_sum_in;
    add8_final_out = add8_final_in1 + add8_final_in2;
end

endmodule
