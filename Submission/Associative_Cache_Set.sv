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
