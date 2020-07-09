`timescale 1ns / 1ps

/////////////////////////////////////////////////////////////////////////////////////

module MCU#(	
		parameter LFSR_SEED_VALUE       = 575,
		parameter NO_OF_INPUT_NEURONS   = 100,
		parameter NO_OF_HIDDEN_NEURONS  = 200,
		parameter NO_OF_OUTPUT_NEURONS  = 10,
		parameter LEARNING_RATE			= 10,
		parameter INPUT_BIT_WIDTH  		= 8,
		parameter OUTPUT_BIT_WIDTH  	= 4,
		parameter HIDDEN_BIT_WIDTH		= 8,
		parameter Q 					= 14,
		parameter N 					= 16
    )(
		input wire clk,
		input wire reset,
		input wire learn_flag,
		input wire input_enable,
		input wire[(INPUT_BIT_WIDTH-1):0] pixel_in,
		input wire[(OUTPUT_BIT_WIDTH-1):0] input_label,
		output reg[(OUTPUT_BIT_WIDTH-1):0] output_data,
		output reg ready
    );
 
    // Constants used within this module
    parameter [3:0] INITIALIZAION       = 4'b0000,
                    READ_INPUT          = 4'b0001,
                    BROADCAST_INPUT     = 4'b0010,
                    READ_H_MATRIX       = 4'b0011,
                    OUTPUT_LAYER        = 4'b0100,
                    SIGMOID_OUTPUT      = 4'b0101,
                    OUTPUT_ERROR        = 4'b0110,
                    LEARN_MODULE        = 4'b1000,
                    SEND_OUTPUT         = 4'b1001,
                    WAIT_FOR_INPUT      = 4'b1010,
                    IDLE_MCU            = 4'b1111;
    parameter [7:0] ALPHA = 8'b0_0_000110;
                    
    // Variables used in this module
    reg [3:0] MCU_state;
    reg lfsr_feedback;
    reg [N-1:0] lfsr_temp;
    reg [31:0] lfsr_ptr;
    reg [31:0] temp_var;
    reg [31:0] counter;
    reg [31:0] counter_1;
    reg data_en;
    reg transfer_en;
    reg [N-1:0] pixel_value;
    reg transfer_flag;
    reg waste_one_cycle;
    reg [(N-1):0] label_one_hot[0:9];
    reg [(N-1):0] error[0:9];
    reg [(2*N)-1:0] sigmoid_input;
    reg [N-1:0] sigmoid_out;
	reg [(2*N)-1:0] mac_result;
    reg [N-1:0]   mul_op_weight;
    reg [(2*N)-1:0] output_added [0:9];
    reg [N-1:0] sigmoid_output [0:9];
    reg [(2*N)-1:0] adder_input;
    reg [(OUTPUT_BIT_WIDTH-1):0] neuron_count;
    reg [N-1:0] data_mul_op;
    reg [(2*N)-1:0] h_matrix_pointer;
    reg [(2*N)-1:0] op_wt_pointer;
    reg [(2*N)-1:0] op_wt_pointer_write;
    reg last_add_flag; 
    reg [N-1:0] add_op1;
    reg [N-1:0] add_op2;
    reg [N-1:0] output_weight_upd;
    reg memory_write;
    reg [N-1:0] weight_backup;
    reg [N-1:0] max_value;
    reg [OUTPUT_BIT_WIDTH-1:0] max_index;
    reg [OUTPUT_BIT_WIDTH-1:0] i;
	
	wire [(N-1):0] serial_in_data;
    wire clk_not;
	wire [N-1:0] neuron_to_neuron [0:NO_OF_HIDDEN_NEURONS];
    wire [N-1:0] sub_result;
	wire [N-1:0]  mul_result;
    wire[(2*N)-1:0] temp_mac_result;
    
    // Variables related to memory to store the input image pixels
    (*ram_style="block"*) reg [(N-1):0] input_pixels [(2**(INPUT_BIT_WIDTH))-1:0];
    reg wr_en_ip_pl;
    reg [N-1:0]  address_ip_pl;
    reg[(N-1):0] data_in_ip_pl;
    reg[(N-1):0] data_out_ip_pl;
    
	// Variables related to memory to store the output neuron weights
    (*ram_style="block"*) reg [(N-1):0] output_weight [(2**(HIDDEN_BIT_WIDTH+OUTPUT_BIT_WIDTH))-1:0];
    reg wr_en_op_wt;
    reg[(HIDDEN_BIT_WIDTH+OUTPUT_BIT_WIDTH)-1:0]  address_op_wt;
    reg[(N-1):0] data_in_op_wt;
    reg[(N-1):0] data_out_op_wt;  
    
    // Variables related to memory to store the H - matrix
    (*ram_style="block"*) reg [(N-1):0] h_matrix [(2**HIDDEN_BIT_WIDTH)-1:0];
    reg wr_en_h_mat;
    reg[(HIDDEN_BIT_WIDTH-1):0]  address_h_mat;
    reg[(N-1):0] data_in_h_mat;
    reg[(N-1):0] data_out_h_mat;

    assign neuron_to_neuron[0] = 0;
    assign serial_in_data = neuron_to_neuron [NO_OF_HIDDEN_NEURONS];
    assign clk_not = ~clk;
    
	// Instantiating the hidden neurons
    generate
		genvar neuron_no;
			for (neuron_no = 0; neuron_no < NO_OF_HIDDEN_NEURONS; neuron_no = neuron_no + 1)
			begin : neuron_inst
				Neuron #(
					.LFSR_SEED_VALUE       	(LFSR_SEED_VALUE),     
					.NO_OF_INPUT_NEURONS   	(NO_OF_INPUT_NEURONS), 
					.NO_OF_HIDDEN_NEURONS  	(NO_OF_HIDDEN_NEURONS),
					.NO_OF_OUTPUT_NEURONS  	(NO_OF_OUTPUT_NEURONS),
					.LEARNING_RATE			(LEARNING_RATE),			
                    .INPUT_BIT_WIDTH  	    (INPUT_BIT_WIDTH),  			
					.OUTPUT_BIT_WIDTH  		(OUTPUT_BIT_WIDTH), 			
					.HIDDEN_BIT_WIDTH		(HIDDEN_BIT_WIDTH),		
					.Q 						(Q),					
					.N 						(N) 				
				) neuron_number (
					.clk          (clk_not),
					.reset        (reset),
					.neuron_id    (neuron_no), //[(HIDDEN_BIT_WIDTH-1):0]),
					.data_en      (data_en),
					.pixel        (pixel_value),
					.transfer_en  (transfer_en),
					.data_in      (neuron_to_neuron[neuron_no]),
					.data_out     (neuron_to_neuron[neuron_no + 1])
				);
			end
    endgenerate
    
	// Instantiating adders and multipliers
    fixed_add #( 
        .Q (Q),
        .N (N)
    ) op_neu_adder (
        .a (mul_result),
        .b (mac_result),
        .c (temp_mac_result)
    );
    
    fixed_add_2 #( 
        .Q (Q),
        .N (N)
    ) error_adder (
        .a (add_op1),
        .b (add_op2),
        .c (sub_result)
    );
    
    fixed_mult #( 
        .Q (Q),
        .N (N)
    ) op_neu_mul (
        .i_multiplicand (data_mul_op),
        .i_multiplier   (mul_op_weight),
        .o_result       (mul_result)
    );
     
    always @(posedge clk)
    begin
        if(reset == 1'b0)
        begin
            MCU_state       = INITIALIZAION;
            lfsr_temp       = LFSR_SEED_VALUE * (counter+5);
            lfsr_feedback   = 0;
            lfsr_ptr        = 0;
            counter         = 0;
            counter_1       = 0;
            temp_var        = 0;
            data_en         = 0;
            transfer_en     = 1'b0;
            transfer_flag   = 1'b0;
            wr_en_ip_pl     = 1'b0;
            wr_en_op_wt     = 1'b0;
            wr_en_h_mat     = 1'b0;
            h_matrix_pointer= 0;
            op_wt_pointer   = 0;
            waste_one_cycle = 1'b0;
            data_mul_op     = 0;
            mul_op_weight   = 0;
            neuron_count    = 0;
            last_add_flag   = 0;
            for (i=0;i<NO_OF_OUTPUT_NEURONS;i=i+1) output_added[i] 	= 0;
            for (i=0;i<NO_OF_OUTPUT_NEURONS;i=i+1) sigmoid_output[i]= 0;
            for (i=0;i<NO_OF_OUTPUT_NEURONS;i=i+1) label_one_hot[i] = 0;
            add_op1     	= 0;
            add_op2     	= 0;
            op_wt_pointer_write =0;
            max_index 		= 0;
            max_value 		= 0;
            output_data     = {OUTPUT_BIT_WIDTH{0}};
        end
        else
        begin
            case (MCU_state)
                INITIALIZAION:
                begin
                   if(counter < NO_OF_HIDDEN_NEURONS)
                   begin
                        if(counter_1 < NO_OF_OUTPUT_NEURONS)
                        begin
                            wr_en_op_wt     = 1'b1;
                            address_op_wt   = lfsr_ptr;
                            output_weight_lfsr();
                            data_in_op_wt   = {lfsr_temp[N-1],1'b0,lfsr_temp[N-3:0]};  ///////////////// Change here
                            counter_1       = counter_1 + 1;     
                        end
                        else
                        begin
                            counter_1   = 0;
                            counter     = counter + 1;
                            lfsr_temp   = LFSR_SEED_VALUE * (counter+5);
                         end
                    end
                    else
                    begin
                        counter         = 0;
                        counter_1       = 0;
                        wr_en_op_wt     = 1'b0; 
                        ready           = 1'b1;
                        MCU_state       = WAIT_FOR_INPUT;
                    end
                end
                WAIT_FOR_INPUT:
                begin
                    if(input_enable)
                    begin
                        MCU_state   = READ_INPUT;
                        counter     = 0;
                    end
                end
                READ_INPUT:
                begin
                    if(input_enable)
                    begin
                        ready           = 1'b0;
                        wr_en_ip_pl     = 1;
                        address_ip_pl   = counter;
                        data_in_ip_pl   = pixel_in;
                        counter         = counter+1;      
                    end
                    else
                    begin
                        counter_1       = 0;
                        counter         = 0;
                        MCU_state       = BROADCAST_INPUT;
                        wr_en_ip_pl     = 1'b0;
                    end
                end
                BROADCAST_INPUT:
                begin
                    if(counter < NO_OF_INPUT_NEURONS)
                    begin
                        pixel_value     = data_out_ip_pl;
                        data_en         = 1'b1;
                        counter         = counter + 1;
                        address_ip_pl   = counter;
                    end
                    else
                    begin
                        counter     = 0;
                        data_en     = 1'b0;
                        MCU_state   = READ_H_MATRIX;
                    end
                end
                READ_H_MATRIX:
                begin
                    if(counter < NO_OF_HIDDEN_NEURONS)
                    begin
                        if(transfer_flag)
                        begin
                            wr_en_h_mat     = 1'b1;
                            address_h_mat   = counter-1;
                            data_in_h_mat   = serial_in_data;   
                        end
                        transfer_en     = 1'b1;
                        transfer_flag   = 1'b1;   
                        counter         = counter +1;
                    end
                    else
                    begin
                        wr_en_h_mat     = 1'b1;
                        address_h_mat   = counter-1;
                        data_in_h_mat   = serial_in_data;
                        transfer_en     = 1'b0;
                        transfer_flag   = 1'b0;
                        counter         = 0;
                        MCU_state       = OUTPUT_LAYER;
                        waste_one_cycle = 1'b1;
                    end
                end
                OUTPUT_LAYER:
                begin
                    if(waste_one_cycle)
                    begin
                        wr_en_op_wt     = 1'b0;
                        op_wt_pointer   = 0;
                        h_matrix_pointer= 0;
                        address_op_wt   = op_wt_pointer;
                        wr_en_h_mat     = 1'b0;
                        address_h_mat   = h_matrix_pointer;
                        mac_result      = 0;
                        counter         = 0;
                        waste_one_cycle = 0;
                    end
                    else
                    begin
                        if(neuron_count ==0 && counter == 0)
                        begin
                            data_mul_op     = data_out_h_mat;
                            mul_op_weight   = data_out_op_wt;
                            neuron_count    = neuron_count+1;
                            op_wt_pointer   = op_wt_pointer + 1;
                            address_h_mat   = op_wt_pointer;
                        end
                        else
                        begin
                            if(last_add_flag == 0)
                            begin
                                if(neuron_count == 0)
                                begin
                                    output_added[OUTPUT_BIT_WIDTH-1] = temp_mac_result;
                                end
                                else
                                begin
                                    output_added[neuron_count - 1] = temp_mac_result;
                                end
                                data_mul_op     = data_out_h_mat;
                                mul_op_weight   = data_out_op_wt;
                                mac_result      = output_added[neuron_count];
                                neuron_count    = neuron_count +1;
                                last_add_flag   = 0;
                                op_wt_pointer   = op_wt_pointer + 1;
                                address_op_wt   = op_wt_pointer;
                            end
                            else
                            begin
                                output_added[OUTPUT_BIT_WIDTH-1]     = temp_mac_result;
                                h_matrix_pointer    = 0;
                                op_wt_pointer       = 0;
                                counter             = 0;
                                neuron_count        = 0; 
                                MCU_state           = SIGMOID_OUTPUT;
                            end
                            if(neuron_count == NO_OF_OUTPUT_NEURONS)
                            begin
                                if(counter == NO_OF_HIDDEN_NEURONS-1)
                                begin
                                    last_add_flag =1;
                                end
                                counter             = counter+ 1;
                                neuron_count        = 0;
                                h_matrix_pointer    = h_matrix_pointer+1;
                                address_h_mat       = h_matrix_pointer;
                            end
                        end
                    end
                end
                SIGMOID_OUTPUT:
                begin
                    if(counter < NO_OF_OUTPUT_NEURONS)
                    begin
                        sigmoid_input           = output_added[counter];
                        sigmoid();
                        sigmoid_output[counter] = sigmoid_out;
                        if(learn_flag)
                            begin
                            if(counter[OUTPUT_BIT_WIDTH-1:0] == input_label[OUTPUT_BIT_WIDTH-1:0])
                            begin
                                label_one_hot[counter] = {{1'b0},{1'b1},{(N-2){1'b0}}};
                            end
                            else
                            begin
                                label_one_hot[counter] = {{1'b0},{1'b1},{(N-2){1'b0}}};
                            end
                        end
                        if(sigmoid_output[counter][N-2:0] > max_value [N-2:0])
                        begin
                            max_value[N-2:0]  = sigmoid_output[counter][N-2:0];
                            max_index[OUTPUT_BIT_WIDTH-1:0]  = counter[OUTPUT_BIT_WIDTH-1:0];
                        end
                        counter = counter + 1;  
                    end
                    else
                    begin
                        counter = 0;
                        if(learn_flag)
                        begin
                            waste_one_cycle = 1'b1;
                            MCU_state       = OUTPUT_ERROR;
                        end
                        else
                        begin
                            MCU_state   = SEND_OUTPUT;
                        end
                    end
                end  
                OUTPUT_ERROR:
                begin
                    if(counter < NO_OF_OUTPUT_NEURONS)
                    begin
                        sigmoid_output[counter][N-1] = 1'b1;
                        add_op2 = sigmoid_output[counter][N-1:0];
                        add_op1 = label_one_hot[counter][N-1:0];
                        if(waste_one_cycle)
                        begin
                            waste_one_cycle = 1'b0;
                            transfer_flag = 1'b1;
                        end
                        else
                        begin
                            if(transfer_flag)
                            begin
                                transfer_flag = 1'b0;   
                            end
                            else
                            begin
                                error[counter-2] = mul_result;    
                            end
                            data_mul_op     = sub_result;
                            mul_op_weight   = ALPHA;
                        end
                        counter = counter + 1;
                    end
                    else
                    begin
                        
                        error[counter-2]	= mul_result;
                        data_mul_op     	= sub_result;
                        mul_op_weight   	= ALPHA;
                        waste_one_cycle 	= 1'b1;
                        add_op1             = {N{1'b0}};
                        add_op2             = {N{1'b0}};
                        MCU_state           = LEARN_MODULE;
                        h_matrix_pointer    = 0;
                        op_wt_pointer       = 0;
                        address_h_mat       = h_matrix_pointer;
                        wr_en_op_wt         = 1'b0;
                        address_op_wt       = op_wt_pointer;
                        wr_en_h_mat         = 1'b0;
                    end
                end  
                LEARN_MODULE:
                begin
                    if (waste_one_cycle == 1)
                    begin
                        error[counter-1]    = mul_result;
                        counter             = 0;
                        counter_1           = 0;
                        waste_one_cycle     = 1'b0;
                        data_mul_op         = data_out_h_mat;
                        mul_op_weight       = error[counter_1];
                        counter_1           = counter_1 + 1;
                        memory_write        = 1;
                        weight_backup       = data_out_op_wt;
                        op_wt_pointer_write = -1;
                    end
                    else
                    begin
                       if(memory_write)
                       begin
                            add_op2         = weight_backup;
                            add_op1         = mul_result;
                            memory_write    = 0;
                            wr_en_op_wt     = 1'b0;    
                            data_mul_op     = data_out_h_mat;
                            mul_op_weight   = error[counter_1];
                            op_wt_pointer   = op_wt_pointer+1;
                            address_op_wt   = op_wt_pointer;
                            counter_1       = counter_1+1;                            
                        end
                        else
                        begin
                             memory_write    = 1;
                             weight_backup   = data_out_op_wt;
                             op_wt_pointer_write = op_wt_pointer_write+1;
                             address_op_wt   = op_wt_pointer_write;
                             wr_en_op_wt     = 1'b1;
                             data_in_op_wt   = sub_result;
                             if(counter_1 == NO_OF_OUTPUT_NEURONS)
                             begin
                                 counter_1 = 0;
                                 counter   = counter +1;
                                 h_matrix_pointer = h_matrix_pointer +1;
                                 address_h_mat  = h_matrix_pointer;
                                 if(counter == NO_OF_HIDDEN_NEURONS)
                                 begin
                                      MCU_state             = SEND_OUTPUT;
                                      counter               = 0;
                                      counter_1             = 0;
                                      h_matrix_pointer      = 0;
                                 end
                             end
                        end
                    end
                end
                SEND_OUTPUT:
                begin
                    output_data[3:0]    = max_index[3:0];
                    ready               = 1'b1;
                    max_value           = {N{1'b0}};
                    max_index           = {OUTPUT_BIT_WIDTH{1'b0}};
                    MCU_state           = WAIT_FOR_INPUT;
                    
                    for (i=0;i<NO_OF_OUTPUT_NEURONS;i=i+1) output_added[i] 	= 0;
                    for (i=0;i<NO_OF_OUTPUT_NEURONS;i=i+1) sigmoid_output[i]= 0;
                    for (i=0;i<NO_OF_OUTPUT_NEURONS;i=i+1) label_one_hot[i] = 0;
                    add_op1     	= 0;
                    add_op2     	= 0;
                    last_add_flag   = 0;
                end
                default:
                begin
                    // Do nothing
                end
            endcase
        end
    end
       
    // BRAM controller for input pixels
    always @(posedge clk) 
    begin
        data_out_ip_pl    <= input_pixels[address_ip_pl];
        if(wr_en_ip_pl) 
        begin
            data_out_ip_pl              <= data_in_ip_pl;
            input_pixels[address_ip_pl] <= data_in_ip_pl;
        end
    end
    
    // BRAM controller for output weigths
    always @(posedge clk) 
    begin
        data_out_op_wt    <= output_weight[address_op_wt];
        if(wr_en_op_wt) 
        begin
            data_out_op_wt              <= data_in_op_wt;
            output_weight[address_op_wt]<= data_in_op_wt;
        end
    end
    
    // BRAM controller for H-matrix
    always @(posedge clk) 
    begin
        data_out_h_mat    <= h_matrix[address_h_mat];
        if(wr_en_h_mat) 
        begin
            data_out_h_mat          <= data_in_h_mat;
            h_matrix[address_h_mat] <= data_in_h_mat;
        end
    end
    
    // LFSR function to generate input weights
    task output_weight_lfsr;
        begin        
            lfsr_feedback 	= lfsr_temp[15] ^ lfsr_temp[14] ^lfsr_temp[13] ^ lfsr_temp[3];
            lfsr_temp     	= lfsr_temp >> 1;
            lfsr_temp[N-1] 	= lfsr_feedback;
            lfsr_ptr      	= lfsr_ptr + 1;
        end
    endtask
   
    task sigmoid;
        begin
            if (sigmoid_input[(2*N)-2:N-2] >= 2)
            begin
               if (sigmoid_input[(2*N)-1] == 1'b1)
               begin
                    sigmoid_out = 0;
               end
               else
               begin
                    sigmoid_out = 0;    
                    sigmoid_out[N-2] = 1'b1; 
               end
                end
                else
                begin
                    sigmoid_out[N-1] = 1'b0;
                    if (sigmoid_input[(2*N)-1] == 0)
                    begin
                        sigmoid_out[N-2:0] = sigmoid_input[N:2] + {{1'b0},{1'b1},{(N-3){1'b0}}};
                    end
                    else
                    begin 
                        sigmoid_out[N-2:0] = {{1'b0},{1'b1},{(N-3){1'b0}}} - sigmoid_input[N:2];
                    end     
                end        
            end
        endtask       
        
endmodule
