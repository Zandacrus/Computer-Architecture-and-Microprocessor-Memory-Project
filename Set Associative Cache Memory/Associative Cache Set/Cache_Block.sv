// Swayam Pal

module CACHE_BLOCK(offset_in,data_size_in,enable_signal,read_signal,write_signal,valid_bit_out,dirty_bit_out,data_out,data_in,block_data_in,block_data_out,replace_block_in);
	
	parameter cache_block = 64*8, MINIMUM_ADDRESSIBLE_SIZE = 8,OFFSET_WIDTH = 6,DATA_WIDTH = 64,no_of_ways = 2;
	
	import FUNCTIONS::log, FUNCTIONS::and_itself,FUNCTIONS::or_itself;
	
	input logic [OFFSET_WIDTH-1:0] offset_in ;
	input logic enable_signal, read_signal, write_signal, replace_block_in;
	input logic [log(DATA_WIDTH):0] data_size_in;
	input logic [DATA_WIDTH-1:0] data_in;
	input logic [cache_block-1:0] block_data_in;
	
	output logic valid_bit_out;
	output logic dirty_bit_out;
	output logic [DATA_WIDTH-1:0] data_out;
	output logic [cache_block-1:0] block_data_out;
	
	
	logic [OFFSET_WIDTH-1:0] offset;
	logic [log(DATA_WIDTH)-1:0] data_size;
	logic [(cache_block/MINIMUM_ADDRESSIBLE_SIZE)-1:0][MINIMUM_ADDRESSIBLE_SIZE-1:0] data;
	logic [(cache_block/MINIMUM_ADDRESSIBLE_SIZE)-1:0] valid_bit  = 'b0;
	logic [(cache_block/MINIMUM_ADDRESSIBLE_SIZE)-1:0] dirty_bit = 'b0;
	logic [DATA_WIDTH-1:0] data_in_reg;
	logic [cache_block-1:0] block_data_out_reg;
	
	assign offset = offset_in;
	assign data_size = data_size_in;
	
	always @(posedge enable_signal) begin
		data_in_reg = data_in;
		if(replace_block_in) begin
			dirty_bit_out = or_itself(dirty_bit, 0, (cache_block/MINIMUM_ADDRESSIBLE_SIZE)-1);
			block_data_out = data;
			data = block_data_in;
			dirty_bit = 'b0;
			valid_bit = '{(cache_block/MINIMUM_ADDRESSIBLE_SIZE){1'b1}};
		end
		unique if(read_signal) begin
			
			data_out = 'b0;
			for (int i = offset; i > offset-(data_size/MINIMUM_ADDRESSIBLE_SIZE); i -= 1) begin
				data_out += data[i];
				if (i!=(offset+1-(data_size/MINIMUM_ADDRESSIBLE_SIZE))) data_out <<= MINIMUM_ADDRESSIBLE_SIZE;
			end
		end
	
		else if (write_signal) begin
			
			for (int i = offset-(data_size/MINIMUM_ADDRESSIBLE_SIZE)+1; i <= offset; i += 1) begin
				data[i] = data_in_reg[MINIMUM_ADDRESSIBLE_SIZE-1:0];
				data_in_reg >>= MINIMUM_ADDRESSIBLE_SIZE;
			end
		end
	
		else begin
			valid_bit_out = and_itself(valid_bit, offset-(data_size/MINIMUM_ADDRESSIBLE_SIZE)+1, offset);
			dirty_bit_out = or_itself(dirty_bit, offset-(data_size/MINIMUM_ADDRESSIBLE_SIZE)+1, offset);
		end
	end
endmodule