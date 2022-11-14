/*
	Arkanil
*/

class RANDOM_ADDRESS #(main_mem_size, cache_block, minimum_addressible_size, address_size, max_offset, offset_size);
	
	rand bit [address_size-1:0] temp_address;
	rand bit [offset_size:0] no_of_continuous_address;
	rand bit is_continuous = 'b0;
	
	bit [offset_size:0] counter = 'b0;
	bit [address_size-1:0] address_out;
	
	constraint c_temp_address {
		temp_address < (main_mem_size/minimum_addressible_size);
		(is_continuous) -> temp_address + no_of_continuous_address < (main_mem_size/minimum_addressible_size);
	}
	
	constraint c_no_of_continuous_address {
		no_of_continuous_address > 'b0;
		no_of_continuous_address <= max_offset;
	}
	
	function void continuous_address ();
		
		address_out = temp_address+counter;
		counter += 'b1;
		if (counter==no_of_continuous_address) begin
			counter = 'b0;
			is_continuous = 'b0;
		end
	endfunction
	
	function bit [address_size-1:0] get_address();
		
		if (!is_continuous) begin
			randomize(no_of_continuous_address);
			randomize(is_continuous);
			randomize(temp_address);
		end
		
		if (is_continuous) continuous_address();
		else address_out = temp_address;
		
		return address_out;
		
	endfunction
	
endclass

class RANDOM_DATA #(maximum_data_size, size_of_data_size, minimum_addressible_size);
	
	rand bit [maximum_data_size-1:0] data_out;
	rand bit [size_of_data_size:0] data_size_out;
	
	constraint c_data_size_out {
		data_size_out > 0;
		data_size_out <= maximum_data_size;
		(data_size_out&(minimum_addressible_size-1)) == 'b0; // assuming minimum_addressible_size = 2**something
	}
	
	constraint c_data_out {
		data_out < (2**data_size_out);
	}
	
	function bit [maximum_data_size-1:0] get_data();
		
		randomize(data_out);
		
		return data_out;
		
	endfunction
	
	function bit [size_of_data_size:0] get_data_size();
		
		randomize(data_size_out);
		
		return data_size_out;
		
	endfunction
	
endclass

class RANDOM_READ_WRITE;
	
	rand bit read_write;
	
	bit [1:0] counter = 'b0;
	
	constraint c_read_write {
		(counter<'d3) -> read_write == 'b0;
	}
	
	function bit get_read_write();
		
		randomize(read_write);
		counter += 'b1;
		
		return read_write;
		
	endfunction
	
endclass

module INPUT_GENERATOR (enable, is_cache_busy, data_in, read, write, enable_cache, address_out, data_size_out, data_out);
	
	import FUNCTIONS::log, TESTCASES::TESTCASE_DATA_SIZE, TESTCASES::TESTCASE_DATA, TESTCASES::hit_count, TESTCASES::miss_count;
	
	parameter main_mem_size = 1, cache_block = 1, minimum_addressible_size = 1, maximum_data_size = 1, address_size = log(main_mem_size/minimum_addressible_size), 
	max_offset = (cache_block/minimum_addressible_size), offset_size = log(max_offset), size_of_data_size = log(maximum_data_size),
	QSORT_SIZE = 524, LU_SIZE = 41832, MATRIX_MULTIPLY_16_SIZE = 9075, MATRIX_MULTIPLY_32_SIZE = 67235, SIZE_LIMIT = 8500;
	
	input logic enable, is_cache_busy;
	input logic [maximum_data_size-1:0] data_in;
	
	output logic read, write, enable_cache;
	output logic [address_size-1:0] address_out;
	output logic [size_of_data_size:0] data_size_out;
	output logic [maximum_data_size-1:0] data_out;
	
	RANDOM_ADDRESS #(main_mem_size, cache_block, minimum_addressible_size, address_size, max_offset, offset_size) random_address;
	RANDOM_DATA #(maximum_data_size, size_of_data_size, minimum_addressible_size) random_data;
	RANDOM_READ_WRITE random_read_write;
	
	logic read_write;
	int ins_counter = TESTCASE_DATA_SIZE-1;
	
	initial begin
		random_address = new();
		random_data = new();
		random_read_write = new();
	end
	
	initial begin
		
	end
	
	always begin
		@(posedge enable);
		//address_out = random_address.get_address();
		address_out = TESTCASE_DATA[ins_counter];
		data_size_out = random_data.get_data_size();
		read_write = random_read_write.get_read_write();
		
		if (read_write=='b1) begin
			data_out = random_data.get_data();
			write = 'b1;
			read = 'b0;
		end
		else begin
			write = 'b0;
			read = 'b1;
		end
		
		enable_cache = 'b1;
		ins_counter -= 1;
	end
	
	always begin
		@(negedge is_cache_busy);
		enable_cache = 'b0;
		write = 'b0;
		read = 'b0;
		
		#1
		if (ins_counter<0) begin
			$display("[%0t ns] hit_rate = %7.4f, miss_rate = %7.4f", $time, ((hit_count*100.0)/(hit_count+miss_count)), ((miss_count*100.0)/(hit_count+miss_count)));
			#1 $finish;
		end
		
		//address_out = random_address.get_address();
		address_out = TESTCASE_DATA[ins_counter];
		data_size_out = random_data.get_data_size();
		read_write = random_read_write.get_read_write();
		
		if (read_write=='b1) begin
			data_out = random_data.get_data();
			write = 'b1;
			read = 'b0;
		end
		else begin
			write = 'b0;
			read = 'b1;
		end
		
		enable_cache = 'b1;
		ins_counter -= 1;
	end
	
endmodule:INPUT_GENERATOR
