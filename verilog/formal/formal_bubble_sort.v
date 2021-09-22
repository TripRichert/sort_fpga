
module formal_bubble_sort
  (
   clk,
   rst,

   src_tvalid,
   src_tready,
   src_tdata,

   dest_tvalid,
   dest_tdata,
   dest_tlast,

   data_tready,
   );
localparam ADDR_WIDTH = 2;
localparam DATA_WIDTH=8;
localparam NUM_ELEMS = 2**ADDR_WIDTH;
   
   input clk;   
   input rst;
   input src_tvalid;
   output src_tready;
   input [DATA_WIDTH-1:0] src_tdata;

   output 		  dest_tvalid;
   wire 		  dest_tready;
   input                  data_tready;
   output [DATA_WIDTH-1:0] dest_tdata;
   output 			     dest_tlast;
   
   reg                       init_1z;

   reg 			   rst_1z;

   wire 		  data_tvalid;
   wire 		  data_tready;
   wire [NUM_ELEMS*DATA_WIDTH-1:0] data_tdata;
   wire 			     data_tlast;

   reg [ADDR_WIDTH-1:0]   cnt_for_tlast;
   wire 	 	  src_tlast;
   
   
   initial begin
      cnt_for_tlast <= 0;
   end
   always @(posedge clk) begin
      if (src_tvalid && src_tready) begin
	 if (cnt_for_tlast == 2**ADDR_WIDTH-1) begin
	    cnt_for_tlast <= 0;
	 end else begin
	    cnt_for_tlast <= cnt_for_tlast + 1;
	 end
      end
      
      if (rst) begin
	 cnt_for_tlast <= 0;
      end
   end // always @ (posedge clk)
   
   assign src_tlast = (cnt_for_tlast == 2**ADDR_WIDTH-1) ? !rst && src_tvalid
		      : 1'b0;
      
   stream_bubble_sort #(
   		       .DATA_WIDTH(DATA_WIDTH), 
   		       .ADDR_WIDTH(ADDR_WIDTH)
   		       ) uut (
   			      .clk(clk),
   			      .rst(rst),

   			      .src_tvalid(src_tvalid),
   			      .src_tready(src_tready),
   			      .src_tdata(src_tdata),
   			      .src_tlast(src_tlast),

   			      .dest_tvalid(dest_tvalid),
   			      .dest_tready(dest_tready),
   			      .dest_tdata(dest_tdata),
   			      .dest_tlast(dest_tlast)
   			      );
   

     axistream_pack #(
		    .DATA_WIDTH(DATA_WIDTH),
		    .NUM_PACK(NUM_ELEMS)
		    ) packit (
			   .clk(clk),
			   .rst(rst),

			   .src_tvalid(dest_tvalid),
			   .src_tready(dest_tready),
			   .src_tdata(dest_tdata),
			   .src_tlast(dest_tlast),

			   .dest_tvalid(data_tvalid),
			   .dest_tready(data_tready),
			   .dest_tdata(data_tdata),
			   .dest_tlast(data_tlast)
			   );

   initial begin
      init_1z = 1'b0;
      rst_1z = 1'b0;
   end
      

   always @(posedge clk) begin
      assume(rst || init_1z);      
      init_1z <= 1'b1;
      rst_1z <= rst;

      assert(!(data_tvalid && data_tready) || (
	    (data_tdata[7:0] <= data_tdata[15:8]) && 
	    (data_tdata[15:8] <= data_tdata[23:16]) && 
	    (data_tdata[23:16] <= data_tdata[31:24])));

   end

   

endmodule // formal_bubble_sort
