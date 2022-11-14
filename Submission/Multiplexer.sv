/*
	Arkanil
*/

module MUX (enable, data_in, choice, data_out);
	
	parameter choice_size = 2, data_in_array_size = 32, data_size = 5;
	
	input logic enable;
	input logic [choice_size-1:0] choice;
	input logic [data_in_array_size-1:0][data_size-1:0] data_in;
	
	output logic [data_size-1:0] data_out;
	
	always begin
		@(posedge enable);
		data_out = data_in[choice];
	end
	
endmodule:MUX
