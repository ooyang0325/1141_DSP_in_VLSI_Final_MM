module ACC #(
    parameter AD = 16,
    parameter VL = 8,
    parameter SUM_W = 24,
    parameter WIDTH = SUM_W * VL
)(
    input               clk,
    input               rst_n,
    input               en,
    input   [WIDTH-1:0] d,
    output  [WIDTH-1:0] q
);

reg     [WIDTH-1:0] acc[0:AD-1];
integer             i;

assign q = acc[0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < AD; i = i + 1) begin
            acc[i] <= 0;
        end
    end 
    else if (en) begin
        for (i = 0; i < AD-1; i = i + 1) begin
            acc[i] <= acc[i+1];
        end
        acc[AD-1] <= d;
    end
end

endmodule