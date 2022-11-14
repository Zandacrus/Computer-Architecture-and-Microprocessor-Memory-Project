package FUNCTIONS;
    parameter MINIMUM_ADDRESSIBLE_SIZE = 8,cache_block = 64*8;

    function automatic logic and_itself (logic [(cache_block/MINIMUM_ADDRESSIBLE_SIZE) - 1:0] bits,int start,int ending);
        logic and_output = 'b1;
        for (int i=start;i<=ending;i++) begin
            and_output = (and_output & bits[i]);
        end

        return and_output;
    endfunction

    function automatic logic or_itself(logic[(cache_block/MINIMUM_ADDRESSIBLE_SIZE) - 1:0] bits,int start,int ending);
        logic or_output = 'b0;
        for(int i=start;i<=ending;i++) begin
            or_output = (or_output | bits[i]);
        end
        
        return or_output;
    endfunction

    function automatic int log(int decimal_number);
        int  log_output = 0;
        decimal_number = decimal_number - 1;
        if(decimal_number ==  0) begin
            return 1;
        end
        while(decimal_number > 0) begin
            log_output = log_output + 1;
            decimal_number = decimal_number/2;
        end
        return log_output;
    endfunction

endpackage