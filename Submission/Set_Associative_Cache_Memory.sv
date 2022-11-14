/*
	Arkanil
*/

module SET_ASSOCIATIVE_CACHE_MEMORY(enable_in, read_in, write_in, address_in, data_size_in /* in bits */, data_in, mem_data_in, data_out, busy_out, mem_read_out, mem_write_out, mem_address_out, mem_data_out);
	
	import FUNCTIONS::log;
	
	parameter cache_size = 256*1024*8, cache_block = 64*8, address_size = 29, minimum_addressible_size = 8, maximum_data_size = 64, // in bits
	no_of_ways = 8, no_of_blocks = (cache_size/cache_block), no_of_sets = (no_of_blocks/no_of_ways), index_size = log(no_of_sets), offset_size = log(cache_block/minimum_addressible_size), 
	tag_size = (address_size-index_size-offset_size), way_no_size = log(no_of_ways), mem_address_size = address_size-offset_size;
	
	input logic enable_in, read_in, write_in;
	input logic [address_size-1:0] address_in;
	input logic [log(maximum_data_size):0] data_size_in;
	input logic [maximum_data_size-1:0] data_in;
	input logic [cache_block-1:0] mem_data_in;
	
	output logic busy_out, mem_read_out;
	output wor mem_write_out;
	output logic signed [maximum_data_size-1:0] data_out;
	output wor [mem_address_size-1:0] mem_address_out;
	output wor [cache_block-1:0] mem_data_out;
	
	logic enable = 0, clock = 0, hit_miss, enable_mux1 = 0, enable_mux2 = 0, enable_mux3 = 0, enable_comparator = 0, write = 0, read = 0;
	logic [index_size-1:0] index_in_reg;
	logic [tag_size-1:0] tag_in_reg;
	logic [offset_size-1:0] offset_in_reg;
	logic [no_of_sets-1:0] enable_set = 0;
	logic [no_of_sets-1:0][no_of_ways-1:0][tag_size-1:0] all_tags;
	logic [no_of_sets-1:0][no_of_ways-1:0] all_valid_bits;
	logic [no_of_sets-1:0][no_of_ways-1:0] all_dirty_bits;
	logic signed [no_of_sets-1:0][maximum_data_size-1:0] all_data;
	logic [no_of_ways-1:0][tag_size-1:0] tags;
	logic [no_of_ways-1:0] valid_bits;
	logic [no_of_ways-1:0] dirty_bits;
	logic signed [maximum_data_size-1:0] data;
	logic [no_of_ways-1:0][way_no_size-1:0] all_way_no;
	logic [no_of_ways-1:0] all_comp_result;
	wor [way_no_size-1:0] way_no;
	wor comp_result;
	logic enable_state_checker = 'b0, state, replace_block = 0;
	logic [mem_address_size-1:0] mem_address;
	
	assign mem_address_out = mem_address;
	assign data_out = data;
	
	MUX #(index_size, no_of_sets, no_of_ways*tag_size) all_tags_mux (.enable(enable_mux1), .data_in(all_tags), .choice(index_in_reg), .data_out(tags));
	MUX #(index_size, no_of_sets, no_of_ways) all_valid_bits_mux (.enable(enable_mux1), .data_in(all_valid_bits), .choice(index_in_reg), .data_out(valid_bits));
	MUX #(index_size, no_of_sets, no_of_ways) all_dirty_bits_mux (.enable(enable_mux1), .data_in(all_dirty_bits), .choice(index_in_reg), .data_out(dirty_bits));
	
	MUX #(way_no_size, no_of_ways, 1) valid_bits_mux (.enable(enable_mux2), .data_in(valid_bits), .choice(way_no), .data_out(valid_bit));
	MUX #(way_no_size, no_of_ways, 1) dirty_bits_mux (.enable(enable_mux2), .data_in(dirty_bits), .choice(way_no), .data_out(dirty_bit));
	
	MUX #(index_size, no_of_sets, maximum_data_size) all_data_mux (.enable(enable_mux3), .data_in(all_data), .choice(index_in_reg), .data_out(data));
	
	genvar i;
	generate
		// Sets
		for (i=0; i<no_of_sets; i++) begin
			ASSOCIATIVE_CACHE_SET #(i, index_size, offset_size, tag_size, maximum_data_size, minimum_addressible_size, no_of_ways, cache_block, mem_address_size) set (.enable_signal(enable_set[i]), .read(read), .write(write), .way_no_in(way_no), .tag_in(tag_in_reg), .data_size_in(data_size_in), .offset_in(offset_in_reg), .data_in(data_in), .replace_block_in(replace_block), .block_data_in(mem_data_in), .block_data_out(mem_data_out), .tags_out(all_tags[i]), .valid_bits_out(all_valid_bits[i]), .dirty_bits_out(all_dirty_bits[i]), .data_out(all_data[i]), .mem_write_out(mem_write_out), .mem_address_out(mem_address_out));
		end
		
		// Comparators
		for (i=0; i<no_of_ways; i++) begin
			COMPARATOR #(tag_size, way_no_size, i) comparator (.enable_signal(enable_comparator), .actual_tag_in(tag_in_reg), .tag_in(tags[i]), .way_no_out(all_way_no[i]), .comp_result(all_comp_result[i])); // test way_no
			assign way_no = all_way_no[i];
			assign comp_result = all_comp_result[i];
		end
		
	endgenerate
	
	// State Checker
	STATE_CHECKER state_checker (.enable(enable_state_checker), .valid_bit(valid_bit), .dirty_bit(dirty_bit), .result(state));
	
	assign hit_miss = comp_result&state;
	
	initial begin
		
	end
	
	always begin
		@(posedge enable_in);
		enable = 'b1;
		busy_out = 'b1;
		clock = 'b1;
	end
	
	always begin
		@(negedge clock);
		#1
		if (enable=='b1) clock <= 'b1;
	end
	
	always begin
		@(posedge enable);
		
		tag_in_reg = address_in[tag_size-1+index_size+offset_size:index_size+offset_size];
		index_in_reg = address_in[index_size-1+offset_size:offset_size];
		offset_in_reg = address_in[offset_size-1:0];
		#1 clock <= 'b0;
		
		@(posedge clock);
		enable_set[index_in_reg] = 'b1;
		#3 clock <= 'b0;
		
		@(posedge clock);
		enable_set[index_in_reg] = 'b0;
		enable_mux1 = 'b1;
		#1 clock <= 'b0;
		
		@(posedge clock);
		enable_mux1 = 'b0;
		enable_comparator = 'b1;
		#1 clock <= 'b0;
		
		@(posedge clock);
		enable_comparator = 'b0;
		enable_mux2 = 'b1;
		#1 clock <= 'b0;
		
		@(posedge clock);
		enable_mux2 = 'b0;
		enable_state_checker = 'b1;
		#1 clock <= 'b0;
		
		@(posedge clock);
		enable_state_checker = 'b0;
		
		if (hit_miss=='b0) begin
			// MISS
			mem_address[tag_size+index_size-1:index_size] = tag_in_reg;
			mem_address[index_size-1:0] = index_in_reg;
			mem_read_out = 'b1;
			#1
			replace_block = 'b1;
			mem_address = 'b0;
		end
		
		unique if (read_in=='b1) read = 'b1;
		else if (write_in=='b1) write = 'b1;
		
		enable_set[index_in_reg] = 'b1;
		#3 clock <= 'b0;
		
		@(posedge clock);
		enable_set[index_in_reg] = 'b0;
		if (read=='b1) enable_mux3 = 'b1;
		#1 clock <= 'b0;
		
		@(posedge clock);
		enable_mux3 <= 'b0;
		replace_block <= 'b0;
		read <= 'b0;
		write <= 'b0;
		mem_read_out <= 'b0;
		//mem_write_out <= 'b0;
		enable <= 'b0;
		#1 clock <= 'b0;
		busy_out <= 'b0;
	end
	
endmodule:SET_ASSOCIATIVE_CACHE_MEMORY
