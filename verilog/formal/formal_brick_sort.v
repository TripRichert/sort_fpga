
module formal_brick_sort
  (
   clk,
   rst,

   src_tvalid,
   src_tready,
   src_tdata,

   dest_tvalid,
   dest_tready,
   dest_tdata
   );

   localparam NUM_ELEMS = 4;
   localparam DATA_WIDTH=8;
   
   input clk;   
   input rst;
   input src_tvalid;
   output src_tready;
   input [DATA_WIDTH*NUM_ELEMS-1:0] src_tdata;

   output 		  dest_tvalid;
   input 		  dest_tready;
   output [DATA_WIDTH*NUM_ELEMS-1:0] dest_tdata;

   reg                       init_1z;

   reg 			   rst_1z;
   wire [DATA_WIDTH-1:0]    dest_data [NUM_ELEMS-1:0];


   

   

   brick_sort #(
		       .DATA_WIDTH(DATA_WIDTH), 
		       .NUM_ELEMS(NUM_ELEMS)//, 
		       ) uut (
			      .clk(clk),
			      .rst(rst),

			      .src_tvalid(src_tvalid),
			      .src_tready(src_tready),
			      .src_tdata_raw(src_tdata),

			      .dest_tvalid(dest_tvalid),
			      .dest_tready(dest_tready),
			      .dest_tdata_raw(dest_tdata)
			      );
   

   





   genvar i;
   for(i = 0; i < NUM_ELEMS; i = i+1) begin
      assign dest_data[i] = dest_tdata[(i+1)*DATA_WIDTH-1: i*DATA_WIDTH];
   end
      
   initial begin
      init_1z = 1'b0;
      rst_1z = 1'b0;
   end
      

   always @(posedge clk) begin
      assume(rst || init_1z);      
      init_1z <= 1'b1;
      rst_1z <= rst;

      assert(!(dest_tvalid && dest_tready) || (
	     (dest_tdata[7:0] <= dest_tdata[15:8]) && 
		  (dest_tdata[15:8] <= dest_tdata[23:16]) && 
	     (dest_tdata[23:16] <= dest_tdata[31:24])));
      
   end

   

endmodule // formal_brick_sort
