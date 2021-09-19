module insertion_sort
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
   dest_tlast,

   tlast_err
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

   output tlast_err;
   

   localparam SM_SORT = 1'b0;
   localparam SM_EJECT = 1'b1;

   reg [DATA_WIDTH-1:0] data_buf [2**ADDR_WIDTH-1:0];
   
   reg 	  sm;
   reg [ADDR_WIDTH:0] cnt;
   wire 	      tlast;
   
   integer 	      i;

   //if we are full, just sort
   assign tlast = ((cnt == 2**ADDR_WIDTH-1) && (sm == SM_SORT))?src_tvalid : src_tlast;
   assign tlast_err = tlast && !src_tlast && src_tvalid && src_tready;
   assign src_tready = (sm == SM_SORT) && !rst ;
   assign dest_tvalid = (sm == SM_EJECT) && !rst;
   assign dest_tdata = data_buf[0];
   assign dest_tlast = (sm == SM_EJECT) && cnt == 1 && dest_tvalid;
   
   
   
   always @(posedge clk) begin
      if (src_tvalid && src_tready) begin
	 case (sm)
	   SM_SORT: begin
 	      data_buf[0] <= (cnt == 0)?src_tdata:
			    (data_buf[0] > src_tdata)?src_tdata : data_buf[0];
	      for (i = 1; i < 2**ADDR_WIDTH-1; i = i + 1) begin
		 if (i < cnt) begin
		    data_buf[i] <= (data_buf[i - 1] >= src_tdata)?data_buf[i-1]:
				   (data_buf[i] >= src_tdata)?src_tdata:
				   data_buf[i];
		 end else if (i == cnt) begin
		    data_buf[i] <= (data_buf[i - 1] >= src_tdata)?data_buf[i-1]:
				   src_tdata;
		 end else begin
		    data_buf[i] <= data_buf[i - 1];
		 end
	      end 
	   end 
	   SM_EJECT: begin
	     //should never be reached
	      for (i = 1; i < 2**ADDR_WIDTH-1; i = i + 1) begin
		 data_buf[i] <= data_buf[i];
	      end
	   end    
	 endcase // case (sm)
      end else if (dest_tvalid && dest_tready) begin
	 for (i = 0; i < 2**ADDR_WIDTH-2; i = i + 1) begin
	    data_buf[i] <= data_buf[i + 1];
	 end
      end else begin
	 for (i = 0; i < 2**ADDR_WIDTH-1; i = i + 1) begin
	    data_buf[i] <= data_buf[i];	 
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

      case (sm)
	SM_SORT: sm <= (src_tvalid && src_tready && tlast)? SM_EJECT:SM_SORT;
	SM_EJECT: sm <= (dest_tvalid && dest_tready && dest_tlast)? SM_SORT:
			SM_EJECT;
      endcase
      

      if (rst) begin
	 cnt <= 0;
	 sm <= SM_SORT;
      end
   end // always @ (posedge clk)

endmodule // insertion_sort
