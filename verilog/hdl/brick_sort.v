module brick_sort
   (
    clk,
    rst,

    src_tvalid,
    src_tready,
    src_tdata_raw,

    dest_tvalid,
    dest_tready,
    dest_tdata_raw,
    );
   parameter NUM_ELEMS = 16;
   parameter DATA_WIDTH = 8;
   
   input   clk;
   input   rst;
   input   src_tvalid;
   output  src_tready;
   input [DATA_WIDTH*NUM_ELEMS-1:0] src_tdata_raw;

   output                 dest_tvalid;
   input                  dest_tready;
   output [DATA_WIDTH*NUM_ELEMS-1:0] dest_tdata_raw;
  

   wire [DATA_WIDTH-1:0]   src_tdata [NUM_ELEMS-1:0];
   wire [DATA_WIDTH-1:0]   dest_tdata [NUM_ELEMS-1:0];

   reg [DATA_WIDTH-1:0]    data_arr [NUM_ELEMS-1:0];
   localparam SM_INIT = 0;
   localparam SM_SORT = 1;
   localparam SM_EJECT = 2;
   reg 	[1:0]		   sm;
   reg 			   sort_even;
   reg [$clog2(NUM_ELEMS*2+1):0] cnter;
   
   genvar k;
   for(k = 0; k < NUM_ELEMS; k = k+1) begin
      assign dest_tdata_raw[(k+1)*DATA_WIDTH-1: k*DATA_WIDTH] = dest_tdata[k];
   end
  
   genvar j;
   for(j = 0; j < NUM_ELEMS; j = j+1) begin
      assign src_tdata[j] = src_tdata_raw[(j+1)*DATA_WIDTH-1: j*DATA_WIDTH];
   end

   genvar L;
   for(L = 0; L < NUM_ELEMS; L = L+1) begin
      assign dest_tdata[L] = data_arr[L];
   end

   assign dest_tvalid = (sm == SM_EJECT)?!rst:1'b0;
   assign src_tready = (sm == SM_INIT)?!rst:1'b0;

   initial begin
      sm <= SM_INIT;
      sort_even <= 1'b0;
      cnter <= 0;
   end
   integer i;
   
   always @(posedge clk) begin
      
      if (src_tvalid && src_tready) begin
	 for (i = 0; i < NUM_ELEMS; i = i + 1) begin
	   data_arr[i] <= src_tdata[i];
	 end
      end
      
      case (sm) 
	SM_INIT: sm <= (src_tvalid && src_tready)?SM_SORT:SM_INIT;
	SM_SORT: sm <= (cnter >= 2*NUM_ELEMS)?SM_EJECT : SM_SORT;
	SM_EJECT: sm <= SM_INIT;
      endcase

      case (sm)
	SM_INIT: sort_even <= 1'b0;
	SM_SORT: sort_even <= !sort_even;
	SM_EJECT: sort_even <= 1'b0;
      endcase

      case (sm)
	SM_INIT: cnter <= 0;
	SM_SORT: cnter <= cnter + 1;
	SM_EJECT: cnter <= 0;
      endcase

      if (sm == SM_SORT) begin
	 if (sort_even) begin
	    for(i = 0; i < NUM_ELEMS - 1; i = i + 2) begin
	       if (data_arr[i] > data_arr[i + 1]) begin
		  data_arr[i + 1] <= data_arr[i];
		  data_arr[i] <= data_arr[i + 1];
	       end
	    end
	 end else begin
	    for(i = 1; i < NUM_ELEMS - 1; i = i + 2) begin
	       if (data_arr[i] > data_arr[i + 1]) begin
		  data_arr[i + 1] <= data_arr[i];
		  data_arr[i] <= data_arr[i + 1];
	       end
	    end
	 end
      end
            
      if (rst) begin
	 sm <= SM_INIT;
	 sort_even <= 1'b0;
	 cnter <= 0;
      end
   end
   
endmodule
