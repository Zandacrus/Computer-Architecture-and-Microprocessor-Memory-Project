/*
	Arkanil
*/

module SET_ASSOCIATIVE_CACHE_MEMORY_TB();
	
	import FUNCTIONS::log, TESTCASES::TESTCASE_DATA_SIZE, TESTCASES::hit_count, TESTCASES::miss_count;
	
	parameter main_mem_size = 1*1024*1024*8, cache_block = 64*8, cache_size = 32*1024*8, no_of_ways = 4, minimum_addressible_size = 8, address_size = log(main_mem_size/minimum_addressible_size), maximum_data_size = 64;
	
	logic ingen_enable_signal, ingen_to_cache_enable_signal, cache_to_mem_read_signal, cache_to_mem_write_signal, ingen_to_cache_read_signal, ingen_to_cache_write_signal, cache_to_ingen_busy_signal;
	logic [cache_block-1:0] cache_to_mem_data, mem_to_cache_data;
	logic [log(main_mem_size/cache_block)-1:0] cache_to_mem_address;
	logic [address_size-1:0] ingen_to_cache_address;
	logic [log(maximum_data_size):0] ingen_to_cache_data_size;
	logic [maximum_data_size-1:0] ingen_to_cache_data, cache_to_ingen_data;
	
	MAIN_MEMORY #(cache_block, main_mem_size) main_mem (.data_in(cache_to_mem_data), .address_in(cache_to_mem_address), .read(cache_to_mem_read_signal), .write(cache_to_mem_write_signal), .data_out(mem_to_cache_data));
	
	INPUT_GENERATOR #(main_mem_size, cache_block, minimum_addressible_size, maximum_data_size) ingen (.enable(ingen_enable_signal), .is_cache_busy(cache_to_ingen_busy_signal), .data_in(cache_to_ingen_data), .read(ingen_to_cache_read_signal), .write(ingen_to_cache_write_signal), .enable_cache(ingen_to_cache_enable_signal), .address_out(ingen_to_cache_address), .data_size_out(ingen_to_cache_data_size), .data_out(ingen_to_cache_data));
	
	SET_ASSOCIATIVE_CACHE_MEMORY #(cache_size, cache_block, address_size, minimum_addressible_size, maximum_data_size, no_of_ways) cache_mem (.enable_in(ingen_to_cache_enable_signal), .read_in(ingen_to_cache_read_signal), .write_in(ingen_to_cache_write_signal), .address_in(ingen_to_cache_address), .data_size_in(ingen_to_cache_data_size) /* in bits */, .data_in(ingen_to_cache_data), .mem_data_in(mem_to_cache_data), .data_out(cache_to_ingen_data), .busy_out(cache_to_ingen_busy_signal), .mem_read_out(cache_to_mem_read_signal), .mem_write_out(cache_to_mem_write_signal), .mem_address_out(cache_to_mem_address), .mem_data_out(cache_to_mem_data));
	
	initial begin
		#1 ingen_enable_signal = 'b1;
	end
	
	always begin
		@(negedge cache_to_ingen_busy_signal);
		
		unique0 if (cache_mem.hit_miss=='b1) hit_count += 1;
		else if (cache_mem.hit_miss=='b0) miss_count += 1;
		
	end
	
endmodule:SET_ASSOCIATIVE_CACHE_MEMORY_TB
