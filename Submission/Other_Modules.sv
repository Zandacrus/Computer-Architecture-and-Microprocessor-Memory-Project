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
	
	import FUNCTIONS::log, TESTCASES::TESTCASE_DATA_SIZE, TESTCASES::TESTCASE_DATA;
	
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
		if (ins_counter<0) $finish;
		
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

// Swayam Pal

module ASSOCIATIVE_CACHE_SET(offset_in,data_out,data_size_in,data_in,tag_in,way_no_in,read,write,enable_signal,tags_out,valid_bits_out,dirty_bits_out,replace_block_in,block_data_in,block_data_out,mem_address_out,mem_write_out);
parameter index_number = 0,index_size = 4,OFFSET_WIDTH = 6, TAG_WIDTH = 26, DATA_WIDTH = 64,MINIMUM_ADDRESSIBLE_SIZE = 8,no_of_ways = 2,cache_block = 64*8,mem_address_size = 32;
  import FUNCTIONS::log;

  input logic [OFFSET_WIDTH-1:0] offset_in;
  input logic [log(no_of_ways)-1:0] way_no_in;
  input logic [DATA_WIDTH-1:0] data_in; // write operation
  input logic [TAG_WIDTH-1:0] tag_in;
  input logic enable_signal;
  input logic write;
  input logic read;
  input logic [log(DATA_WIDTH):0] data_size_in; 
  input logic replace_block_in;
  input logic [cache_block-1:0] block_data_in;

  output logic signed [DATA_WIDTH-1:0] data_out; //read operation
  output logic [no_of_ways-1:0][TAG_WIDTH-1:0] tags_out;
  output logic [no_of_ways-1:0]valid_bits_out;
  output logic [no_of_ways-1:0]dirty_bits_out;
  output logic [cache_block-1:0] block_data_out;
  output logic mem_write_out;
  output logic [mem_address_size-1:0] mem_address_out; 

  
  logic [no_of_ways-1:0] enable_way;
  logic [no_of_ways-1:0][TAG_WIDTH-1:0] tag;
  logic [no_of_ways-1:0][log(no_of_ways)-1:0] counter = 'b0; //state of a data in a way
  logic [no_of_ways-1:0][cache_block-1:0] block_data;
  logic [log(no_of_ways)-1:0] way_no;
  logic  [index_size-1:0] index = index_number;
  logic signed [no_of_ways-1:0][DATA_WIDTH-1:0] data;
  
  genvar i;
  generate;
  for ( i=0; i<no_of_ways; i++) begin
    CACHE_BLOCK #(cache_block, MINIMUM_ADDRESSIBLE_SIZE, OFFSET_WIDTH, DATA_WIDTH, no_of_ways) cache_block(.offset_in(offset_in),.data_size_in(data_size_in),.enable_signal(enable_way[i]),.read_signal(read),.write_signal(write),.data_in(data_in),.block_data_in(block_data_in),.replace_block_in(replace_block_in),.valid_bit_out(valid_bits_out[i]),.dirty_bit_out(dirty_bits_out[i]),.data_out(data[i]),.block_data_out(block_data[i]));
  end
  endgenerate

  always begin
    @(posedge enable_signal);
    #1
    unique if(replace_block_in == 'b1) begin
      
      for(int i=0;i<no_of_ways;i++) begin
          if(counter[i] == 'b0) begin
            way_no = i;
            break;
          end
      end
	  
	  enable_way[way_no] = 'b1;
	  #1
      block_data_out = block_data[way_no];
	  mem_address_out[TAG_WIDTH+index_size-1:index_size] = tag[way_no];
	  mem_address_out[index_size-1:0] = index;
      mem_write_out = 'b1;
      counter[way_no] = 'd7;
	  tag[way_no] = tag_in;
      for(int i=0;i<no_of_ways;i++) begin
        if(i != way_no) begin
          if(counter[i] != 'b0) begin
            counter[i] = counter[i] - 'b1;
          end
        end
      end
    end
    else if(replace_block_in == 'b0) begin
        unique if(read) begin
            enable_way[way_no_in] = 'b1;
			#1 data_out = data[way_no_in];
        end

        else if(write) begin
            enable_way[way_no_in] = 'b1;
        end

        else begin
            enable_way = '{no_of_ways{1'b1}};
            tags_out = tag;
        end
    end
    #1
    mem_write_out = 'b0;
	mem_address_out = 'b0;
	block_data_out = 'b0;
    enable_way = '{no_of_ways{1'b0}};
	end
	
endmodule

