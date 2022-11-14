/*
	Arkanil
*/

module COMPARATOR (enable_signal, actual_tag_in, tag_in, way_no_out, comp_result);
	
	parameter tag_size  = 22, way_no_size = 3, way_no = 0;
	
	input logic enable_signal;
	input logic [tag_size-1:0] actual_tag_in, tag_in;
	
	output logic [way_no_size-1:0] way_no_out;
	output logic comp_result;
	
	always begin
		@(posedge enable_signal);
		
		if (actual_tag_in==tag_in) comp_result = 'b1;
		else comp_result = 'b0;
		
		if (comp_result=='b1) way_no_out = way_no;
		else way_no_out = 'b0;
	end
	
endmodule:COMPARATOR
