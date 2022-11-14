class ADDRESS_GENERATOR #(address_bits, main_memory_size, minimum_data_unit_size);
	
	rand bit [address_bits-1:0] address;
	constraint c_address {address < (main_memory_size/minimum_data_unit_size);}
	
	function bit [address_size-1:0] random_address();
		randomize();
		return address;
	endfunction
endclass
