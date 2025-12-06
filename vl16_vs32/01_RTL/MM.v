module MM #(
    parameter M = 512,
    parameter N = 512,
    parameter K = 128,
    parameter AD = 16,
    parameter VL = 16,
    parameter VS = 32,
    parameter SUM_W = 24, 
    parameter ACC_W = SUM_W * VL,
    parameter m = $clog2(M/VL), // 5
    parameter n = $clog2(N/AD), // 5
    parameter k = $clog2(K/VS), // 2
    parameter ad = $clog2(AD) // 4
)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_in_valid,
    input   [VL*VS*8-1:0]   i_vec_a,
    input   [VS*8-1:0]      i_vec_b,
    output                  o_out_valid,
    output  [ACC_W-1:0]     o_acc
);

reg                     in_valid;
reg  [VL*VS*8-1:0]      vec_a;
reg  [VS*8-1:0]         vec_b;
reg  [m+n+k+ad-1:0]     cnt;
reg                     pre_out_valid;
reg                     partial_sum_rst;
wire [ACC_W-1:0]        partial_sum_in;
wire [ACC_W-1:0]        partial_sum_out;
wire [ACC_W-1:0]        acc_rdata;
reg  [ACC_W-1:0]        acc;
reg                     out_valid;

assign partial_sum_in = partial_sum_rst ? 0 : acc_rdata;
assign o_out_valid = out_valid;
assign o_acc = acc;

genvar vecmac_i;
generate
for (vecmac_i = 0; vecmac_i < VL; vecmac_i = vecmac_i + 1) begin : gen_vecmac
    VECMAC #(.VS(VS), .SUM_W(SUM_W)) vecmac (
        .i_vec_a(vec_a[vecmac_i*VS*8 +: VS*8]), .i_vec_b(vec_b),
        .i_partial_sum_in(partial_sum_in[vecmac_i*SUM_W +: SUM_W]),
        .o_partial_sum_out(partial_sum_out[vecmac_i*SUM_W +: SUM_W])
    );
end
endgenerate

ACC #(.AD(AD), .VL(VL), .SUM_W(SUM_W), .WIDTH(ACC_W)) u_acc (
    .clk(i_clk), .rst_n(i_rst_n), .en(in_valid), 
    .d(partial_sum_out), .q(acc_rdata)
);

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)   in_valid <= 0;
    else            in_valid <= i_in_valid;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        vec_a <= 0;
        vec_b <= 0;
    end 
    else begin
        vec_a <= i_vec_a;
        vec_b <= i_vec_b;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           cnt <= 0;
    else if (i_in_valid)    cnt <= cnt + 1;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        partial_sum_rst <= 1;
        pre_out_valid <= 0;
    end
    else begin
        partial_sum_rst <= ~|cnt[k+ad-1:ad];
        pre_out_valid <= &{cnt[k+ad-1:ad], i_in_valid};
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        out_valid <= 0;
        acc <= 0;
    end
    else if (pre_out_valid) begin
        out_valid <= 1;
        acc <= partial_sum_out;
    end
    else begin
        out_valid <= 0;
        acc <= 0;
    end
end

endmodule