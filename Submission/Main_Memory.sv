/*
	Arkanil
*/

module MAIN_MEMORY (data_in, address_in, read, write, data_out);
	
	import FUNCTIONS::log;
	
	parameter cache_block = 64*8, main_mem_size = 512*1024*1024*8;
	
	input logic read, write;
	input logic [cache_block-1:0] data_in;
	input logic [log(main_mem_size/cache_block)-1:0] address_in;
	
	output logic [cache_block-1:0] data_out;
	
	bit [(main_mem_size/cache_block)-1:0][cache_block-1:0] main_memory = 'b0;
	
	always begin
		
		@(posedge (read|write));
		
		unique if (read=='b1) begin
			data_out <= main_memory[address_in];
		end
		else if (write=='b1) begin
			main_memory[address_in] <= data_in;
		end
		
	end
	
endmodule
