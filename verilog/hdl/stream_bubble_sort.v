module stream_bubble_sort
  (
   clk,
   rst,

   src_tvalid,
   src_tready,
   src_tdata,
   src_tlast,

   dest_tvalid,
   dest_tready,
   dest_tdata,
   dest_tlast
   );
   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 12;

   input clk;
   input rst;

   input  src_tvalid;
   output src_tready;
   input  [DATA_WIDTH-1:0] src_tdata;
   input  src_tlast;

   output dest_tvalid;
   input  dest_tready;
   output [DATA_WIDTH-1:0] dest_tdata;
   output dest_tlast;

   reg   fifo_src_tvalid;
   wire   fifo_src_tready;
   reg [DATA_WIDTH-1:0] fifo_src_tdata;
   reg 		 fifo_src_tlast;

   wire 		 fifo_dest_tvalid;
   wire 		 fifo_dest_tready;
   wire [DATA_WIDTH-1:0] fifo_dest_tdata;
   wire 		 fifo_dest_tlast;

   wire [ADDR_WIDTH:0] 	 fifo_data_cnt;

   reg 		 swapper_src_tvalid;
   wire 		 swapper_src_tready;
   reg [DATA_WIDTH-1:0] swapper_src_tdata;
   reg 		 swapper_src_tlast;

   wire 		 swapper_dest_tvalid;
   wire 		 swapper_dest_tready;
   wire [DATA_WIDTH-1:0] swapper_dest_tdata;
   wire 		 swapper_dest_tlast;

   localparam SM_INIT = 0;
   localparam SM_SORT = 1;
   localparam SM_EJECT = 2;

   reg [1:0] 		 sm;
   reg [ADDR_WIDTH:0] 	 tlast_cnt;
   reg [ADDR_WIDTH:0] 	 pkt_size;
   


   assign src_tready    = (sm == SM_INIT)? (fifo_src_tready && !rst) : 1'b0;
   assign fifo_dest_tready = (sm == SM_INIT)? 1'b0 : !rst && swapper_src_tready;
   assign swapper_dest_tready = (sm == SM_INIT)? 1'b0 : 
				 (sm == SM_SORT) ? fifo_src_tready:dest_tready;

   assign dest_tvalid = (sm == SM_EJECT)?swapper_dest_tvalid && !rst: 1'b0;
   assign dest_tlast = (sm == SM_EJECT)?swapper_dest_tlast && dest_tvalid: 1'b0;
   assign dest_tdata = swapper_dest_tdata;
   
   
   //be careful to avoid latches in async process
   always @* begin
      case (sm)
	SM_INIT: begin
	   fifo_src_tvalid <= src_tvalid;
	   fifo_src_tdata <= src_tdata;
	   fifo_src_tlast <= src_tlast 
			     || (src_tvalid&&(fifo_data_cnt==2**ADDR_WIDTH-1));
	end
	SM_SORT: begin
	   fifo_src_tvalid <= swapper_dest_tvalid;
	   fifo_src_tdata <= swapper_dest_tdata;
	   fifo_src_tlast <= swapper_dest_tlast;
	end
	default: begin
	   fifo_src_tvalid <= 1'b0;
	   fifo_src_tlast <= 1'b0;
	   fifo_src_tdata <= 0;
	end
      endcase // case (sm)

      swapper_src_tdata <= fifo_dest_tdata;
      swapper_src_tlast <= fifo_src_tlast;
      case (sm)
	SM_INIT: begin
	   swapper_src_tvalid <= 1'b0;
	end
	SM_SORT: begin
	   swapper_src_tvalid <= fifo_dest_tvalid;
	end
	default: begin
	   swapper_src_tvalid <= fifo_dest_tvalid;
	end
      endcase // case (sm)
   end // always @ *

   always @(posedge clk) begin
      case (sm)
	SM_INIT: sm <= (fifo_src_tvalid && fifo_src_tready && fifo_src_tlast)?
		       SM_SORT : SM_INIT;
	SM_SORT: sm <= (tlast_cnt == pkt_size)? SM_EJECT : SM_SORT;
	SM_EJECT: sm <= (dest_tvalid && dest_tready && dest_tlast)? 
			SM_INIT : SM_EJECT;	
      endcase // case (sm)
      
      if (fifo_src_tvalid && fifo_src_tready && fifo_src_tlast 
	  && sm == SM_INIT) begin
	 pkt_size <= (fifo_data_cnt != 0) ? fifo_data_cnt - 1 : 0;
      end else begin
	 pkt_size <= pkt_size;
      end

      case (sm)
	SM_INIT: tlast_cnt <= 0;
	SM_SORT: tlast_cnt <= (swapper_dest_tvalid && swapper_dest_tready 
			       && swapper_dest_tlast)?tlast_cnt + 1: tlast_cnt;
	SM_EJECT: tlast_cnt <= 0;
      endcase // case (sm)

      if(rst) begin
	 sm <= SM_INIT;
	 tlast_cnt <= 0;
      end
   end

   bram_axistream_fifo #(
			 .DATA_WIDTH(DATA_WIDTH), 
			 .ADDR_WIDTH(ADDR_WIDTH)
			 ) fifo (
				 .clk(clk),
				 .rst(rst),

				 .src_tvalid(fifo_src_tvalid),
				 .src_tready(fifo_src_tready),
				 .src_tdata(fifo_src_tdata),
				 .src_tlast(fifo_src_tlast),

				 .dest_tvalid(fifo_dest_tvalid),
				 .dest_tready(fifo_dest_tready),
				 .dest_tdata(fifo_dest_tdata),
				 .dest_tlast(fifo_dest_tlast),
				 .data_cnt(fifo_data_cnt)
				 );
   axistream_swapper #(
		       .DATA_WIDTH(DATA_WIDTH)
		       ) swapper (
				  .clk(clk),
				 .rst(rst),
				  
				 .src_tvalid(swapper_src_tvalid),
				 .src_tready(swapper_src_tready),
				 .src_tdata(swapper_src_tdata),
				 .src_tlast(swapper_src_tlast),
				  
				 .dest_tvalid(swapper_dest_tvalid),
				 .dest_tready(swapper_dest_tready),
				 .dest_tdata(swapper_dest_tdata),
				 .dest_tlast(swapper_dest_tlast)
				  );
   
endmodule // stream_bubble_sort
