module axistream_swapper
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

   input clk;
   input rst;

   input src_tvalid;
   output src_tready;
   input  [DATA_WIDTH-1:0] src_tdata;
   input  src_tlast;

   output dest_tvalid;
   input  dest_tready;
   output [DATA_WIDTH-1:0] dest_tdata;
   output 		   dest_tlast;

   reg [DATA_WIDTH-1:0]    data_buf [1:0];
   reg [1:0] 		   cnt;
   reg  		   tlast;

   assign dest_tvalid = (cnt == 2)? !rst : (cnt == 1)?tlast: 1'b0;
   assign src_tready  = (cnt != 2)? !rst && !tlast: !rst && dest_tready && !tlast;

   assign dest_tdata = (tlast && cnt == 1)? data_buf[0] : data_buf[1];
   assign dest_tlast = tlast && (cnt == 1) && dest_tvalid;

   always @(posedge clk) begin
      if (src_tvalid && src_tready) begin
	 tlast <= src_tlast;
	 
	 if (cnt == 0) begin
	    data_buf[0] <= src_tdata;
	    data_buf[1] <= data_buf[1];//don't care
	 end else begin
	    if (src_tdata > data_buf[1]) begin
	       data_buf[0] <= src_tdata;
	       data_buf[1] <= data_buf[0];
	    end else begin
	       data_buf[1] <= src_tdata;
	       data_buf[0] <= data_buf[0];
	    end
	 end 
      end 
      
      if (tlast) begin 
	 if (dest_tvalid && dest_tready) begin
	    tlast <= (cnt == 2);
	 end else begin
	    tlast <= tlast;
	 end
      end
      
      if (src_tvalid && src_tready && !(dest_tvalid && dest_tready)) begin
	cnt <= cnt + 1;
      end else if (!(src_tvalid && src_tready) 
		   && dest_tvalid && dest_tready) begin
	 
	 cnt <= (cnt == 0)?0:cnt - 1;
	 
      end else begin
	 cnt <= cnt;
      end

      if (rst) begin
	 cnt <= 0;
	 tlast <= 1'b0;
      end
      
   end
   
endmodule // axistream_swapper
