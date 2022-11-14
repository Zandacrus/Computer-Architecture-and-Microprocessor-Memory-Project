/*
	Arkanil
*/

module STATE_CHECKER (enable, valid_bit, dirty_bit, result);
	
	input logic enable, valid_bit, dirty_bit;
	
	output logic result;
	
	always begin
		@(posedge enable);
		result = valid_bit;
	end
	
endmodule:STATE_CHECKER
