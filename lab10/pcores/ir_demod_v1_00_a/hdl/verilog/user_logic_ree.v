//----------------------------------------------------------------------------
// user_logic.vhd - module
//----------------------------------------------------------------------------
//
// ***************************************************************************
// ** Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.            **
// **                                                                       **
// ** Xilinx, Inc.                                                          **
// ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
// ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
// ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
// ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
// ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
// ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
// ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
// ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
// ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
// ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
// ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
// ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
// ** FOR A PARTICULAR PURPOSE.                                             **
// **                                                                       **
// ***************************************************************************
//
//----------------------------------------------------------------------------
// Filename:          user_logic.vhd
// Version:           1.00.a
// Description:       User logic module.
// Date:              Tue Mar 19 10:58:32 2013 (by Create and Import Peripheral Wizard)
// Verilog Standard:  Verilog-2001
//----------------------------------------------------------------------------
// Naming Conventions:
//   active low signals:                    "*_n"
//   clock signals:                         "clk", "clk_div#", "clk_#x"
//   reset signals:                         "rst", "rst_n"
//   generics:                              "C_*"
//   user defined types:                    "*_TYPE"
//   state machine next state:              "*_ns"
//   state machine current state:           "*_cs"
//   combinatorial signals:                 "*_com"
//   pipelined or register delay signals:   "*_d#"
//   counter signals:                       "*cnt*"
//   clock enable signals:                  "*_ce"
//   internal version of output port:       "*_i"
//   device pins:                           "*_pin"
//   ports:                                 "- Names begin with Uppercase"
//   processes:                             "*_PROCESS"
//   component instantiations:              "<ENTITY_>I_<#|FUNC>"
//----------------------------------------------------------------------------

module user_logic
(
  // -- ADD USER PORTS BELOW THIS LINE ---------------
  // --USER ports added here
  IR_signal, 
  // -- ADD USER PORTS ABOVE THIS LINE ---------------

  // -- DO NOT EDIT BELOW THIS LINE ------------------
  // -- Bus protocol ports, do not add to or delete 
  Bus2IP_Clk,                     // Bus to IP clock
  Bus2IP_Reset,                   // Bus to IP reset
  Bus2IP_Data,                    // Bus to IP data bus
  Bus2IP_BE,                      // Bus to IP byte enables
  Bus2IP_RdCE,                    // Bus to IP read chip enable
  Bus2IP_WrCE,                    // Bus to IP write chip enable
  IP2Bus_Data,                    // IP to Bus data bus
  IP2Bus_RdAck,                   // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,                   // IP to Bus write transfer acknowledgement
  IP2Bus_Error                    // IP to Bus error response
  // -- DO NOT EDIT ABOVE THIS LINE ------------------
); // user_logic

// -- ADD USER PARAMETERS BELOW THIS LINE ------------
// --USER parameters added here 
// -- ADD USER PARAMETERS ABOVE THIS LINE ------------

// -- DO NOT EDIT BELOW THIS LINE --------------------
// -- Bus protocol parameters, do not add to or delete
parameter C_SLV_DWIDTH                   = 32;
parameter C_NUM_REG                      = 3;
// -- DO NOT EDIT ABOVE THIS LINE --------------------

// -- ADD USER PORTS BELOW THIS LINE -----------------
// --USER ports added here 
input                                     IR_signal;
// -- ADD USER PORTS ABOVE THIS LINE -----------------

// -- DO NOT EDIT BELOW THIS LINE --------------------
// -- Bus protocol ports, do not add to or delete
input                                     Bus2IP_Clk;
input                                     Bus2IP_Reset;
input      [0 : C_SLV_DWIDTH-1]           Bus2IP_Data;
input      [0 : C_SLV_DWIDTH/8-1]         Bus2IP_BE;
input      [0 : C_NUM_REG-1]              Bus2IP_RdCE;
input      [0 : C_NUM_REG-1]              Bus2IP_WrCE;
output     [0 : C_SLV_DWIDTH-1]           IP2Bus_Data;
output                                    IP2Bus_RdAck;
output                                    IP2Bus_WrAck;
output                                    IP2Bus_Error;
// -- DO NOT EDIT ABOVE THIS LINE --------------------

//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------

  // --USER nets declarations added here, as needed for user logic

  // Nets for user logic slave model s/w accessible register example
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg0;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg1;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg2;
  wire       [0 : 2]                        slv_reg_write_sel;
  wire       [0 : 2]                        slv_reg_read_sel;
  reg        [0 : C_SLV_DWIDTH-1]           slv_ip2bus_data;
  wire                                      slv_read_ack;
  wire                                      slv_write_ack;
  integer                                   byte_index, bit_index;

  // --USER logic implementation added here
parameter start_cycle_num = 140000;
parameter one_cycle_num   = 85000;
parameter zero_cycle_num  = 40000;
parameter error_cycle_num = 500000;

parameter high = 2'b11;
parameter low  = 2'b00;
parameter fall = 2'b10;
parameter rise = 2'b01;

reg[1:0] state;
reg[1:0] bit_counter_state, shift_state;
reg shift_reg_in_reg;
reg[31:0] sample_counter;
reg[3:0] bit_counter;
reg[31:0] temp_register;
reg[11:0] shift_register;  // store date

reg clr_sample_counter;
reg clr_bit_counter; // clear bit counter 
reg inc_sample_counter;
reg inc_bit_counter;  // increase bit counter
reg load_temp_reg;
reg clr_shift_reg;
reg shift;
reg shift_reg_in;
reg load;
wire flag;
wire BC_eq_12;
wire SC_bt_error_cycle;

always@(posedge Bus2IP_Clk) 
begin
  if(Bus2IP_Reset==1)
    state <= high;
  else
    state <= {state[0], IR_signal};
end

always@(state, flag, temp_register, SC_bt_error_cycle)
begin
  clr_sample_counter = 0;
  clr_bit_counter = 0;
  inc_sample_counter = 0;
  inc_bit_counter = 0;
  clr_shift_reg = 0;  
  shift_reg_in = 0;
  shift = 0;
  load = 0;
  load_temp_reg = 0;
  case(state)
    high:
	   begin
		  inc_sample_counter = 1;
		  if(SC_bt_error_cycle)
		    begin
			   clr_bit_counter = 1;
				clr_shift_reg = 1;
			 end
		  if(temp_register>start_cycle_num)
		    begin
			   clr_bit_counter = 1;
				clr_shift_reg = 1;
			 end		
		  else if(temp_register>one_cycle_num)
			 begin
				inc_bit_counter = 1;
				shift = 1;
				shift_reg_in = 1;
			 end
		  else if(temp_register>zero_cycle_num)
			 begin
			   inc_bit_counter = 1;
				shift = 1;
				shift_reg_in = 0; // data stand by to put in
			 end			  
		  if(flag)
			 begin
				clr_sample_counter = 1;
				clr_bit_counter = 1;
				clr_shift_reg = 1;
				load = 1;
			 end		 
		end
	 fall:
	   begin
		  clr_sample_counter = 1;
		end
	 low:
	   begin
		  inc_sample_counter = 1;
		end
	 rise:
	   begin
		  clr_sample_counter = 1;
		  load_temp_reg = 1;
		end	   
  endcase
end

assign SC_bt_error_cycle = (sample_counter>error_cycle_num);
assign BC_eq_12 = (bit_counter==12);
assign flag = (sample_counter > 20)&&(BC_eq_12==1);

always@(posedge Bus2IP_Clk)
begin
  if(Bus2IP_Reset==1)
    begin
	   sample_counter <= 0;
		temp_register <= 0;
		slv_reg0 <= 0;
		slv_reg1 <= 0;
	 end
  else
    begin
	   if(clr_sample_counter==1)
		  sample_counter <= 0;
		else if(inc_sample_counter==1)
		  sample_counter <= sample_counter + 1;
		if(load_temp_reg)
		  temp_register <= sample_counter;
		if(load)
		  begin
		    slv_reg0 <= shift_register;
			 slv_reg1 <= slv_reg1 + 1;
		  end
	 end
   slv_reg2 <= bit_counter;
end

always@(posedge Bus2IP_Clk)
begin
  if(Bus2IP_Reset==1)
    bit_counter_state <= 2'b00;
  else
    bit_counter_state <= {bit_counter_state[0], inc_bit_counter};
end

always@(posedge Bus2IP_Clk)
begin
  if(Bus2IP_Reset==1)
        bit_counter <= 0;
  else if(clr_bit_counter==1)
		  bit_counter <= 0;
  else if(bit_counter_state==2'b01)
		  bit_counter <= bit_counter + 1;
  else
	     bit_counter <= bit_counter;
end

always@(posedge Bus2IP_Clk)
begin
  if(Bus2IP_Reset==1)
    shift_state <= 2'b00;
  else
    shift_state <= {bit_counter_state[0], shift};
end

always@(posedge Bus2IP_Clk)
begin
  if(Bus2IP_Reset==1)
    shift_reg_in_reg <= 1'b0;
  else if(state==2'b11)
    shift_reg_in_reg <= shift_reg_in;
  else
    shift_reg_in_reg <= shift_reg_in_reg;
end

always@(posedge Bus2IP_Clk)
begin
  if(Bus2IP_Reset==1)
    shift_register <= 0;
  else if(clr_shift_reg)
    shift_register <=  0;
  else if(shift_state==2'b01)
    shift_register <= {shift_register[10:0], shift_reg_in_reg};
  else
    shift_register <= shift_register;
end
   
  // ------------------------------------------------------
  // Example code to read/write user logic slave model s/w accessible registers
  // 
  // Note:
  // The example code presented here is to show you one way of reading/writing
  // software accessible registers implemented in the user logic slave model.
  // Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  // to one software accessible register by the top level template. For example,
  // if you have four 32 bit software accessible registers in the user logic,
  // you are basically operating on the following memory mapped registers:
  // 
  //    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  //                     "1000"   C_BASEADDR + 0x0
  //                     "0100"   C_BASEADDR + 0x4
  //                     "0010"   C_BASEADDR + 0x8
  //                     "0001"   C_BASEADDR + 0xC
  // 
  // ------------------------------------------------------

  assign
    slv_reg_write_sel = Bus2IP_WrCE[0:2],
    slv_reg_read_sel  = Bus2IP_RdCE[0:2],
    slv_write_ack     = Bus2IP_WrCE[0] || Bus2IP_WrCE[1] || Bus2IP_WrCE[2],
    slv_read_ack      = Bus2IP_RdCE[0] || Bus2IP_RdCE[1] || Bus2IP_RdCE[2];

  // implement slave model register(s)
  /*always @( posedge Bus2IP_Clk )
    begin: SLAVE_REG_WRITE_PROC

      if ( Bus2IP_Reset == 1 )
        begin
          //slv_reg0 <= 0;
          //slv_reg1 <= 0;
          //slv_reg2 <= 0;
        end
      else
        case ( slv_reg_write_sel )
          3'b100 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg0[bit_index] <= Bus2IP_Data[bit_index];
          3'b010 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg1[bit_index] <= Bus2IP_Data[bit_index];
          3'b001 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg2[bit_index] <= Bus2IP_Data[bit_index];
          default : ;
        endcase

    end // SLAVE_REG_WRITE_PROC*/

  // implement slave model register read mux
  always @( slv_reg_read_sel or slv_reg0 or slv_reg1 or slv_reg2 )
    begin: SLAVE_REG_READ_PROC

      case ( slv_reg_read_sel )
        3'b100 : slv_ip2bus_data <= slv_reg0;
        3'b010 : slv_ip2bus_data <= slv_reg1;
        3'b001 : slv_ip2bus_data <= slv_reg2;
        default : slv_ip2bus_data <= 0;
      endcase

    end // SLAVE_REG_READ_PROC

  // ------------------------------------------------------------
  // Example code to drive IP to Bus signals
  // ------------------------------------------------------------

  assign IP2Bus_Data    = slv_ip2bus_data;
  assign IP2Bus_WrAck   = slv_write_ack;
  assign IP2Bus_RdAck   = slv_read_ack;
  assign IP2Bus_Error   = 0;

endmodule
