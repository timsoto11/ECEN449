// user_logic.v
// Author: Peng Li, Sundaresan Adin
// For ECEN449 Lab7
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
// Date:              Thu Oct 17 13:59:07 2013 (by Create and Import Peripheral Wizard)
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
  parameter high = 2'b11;
  parameter low  = 2'b00;
  parameter rise = 2'b01;
  parameter fall = 2'b10;
// -- ADD USER PARAMETERS ABOVE THIS LINE ------------

// -- DO NOT EDIT BELOW THIS LINE --------------------
// -- Bus protocol parameters, do not add to or delete
parameter C_SLV_DWIDTH                   = 32;
parameter C_NUM_REG                      = 3;
// -- DO NOT EDIT ABOVE THIS LINE --------------------

// -- ADD USER PORTS BELOW THIS LINE -----------------
input					  IR_signal;
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
  reg clk_div_16; 	// the min clock cycles('0') for IR_signal is 45000 @ 75MHz
			// this clock is its division of 16
			// hence 16 new clock cycles in signal '0' 
			// 32 new clock cycles in signal '1'
			// 64 new clock cycles in signal 'start'
  reg [15:0] clk_div_cnt; // counter for the div_clock

  reg input_state;	// register to save IR_signal
  reg current_state;	// register to save delay input IR_signal
  reg previous_state;	// register to save delay input IR_signal  

  reg [1:0] state;	// detect IR_signal state: high, low, rise, fall
  
  reg [11:0] data;	// register to store data
  reg [3:0] data_bit;	// pointer for data bit to be read in

  reg rd_flag;		// read flag in data
  reg send_flag;	// flag indicate whether the data be sent
  reg start_flag;	// flag indicate the start signal
  integer cnt_low;	// counter for low state @ 16 div clock rate
  reg data_write_flag; 	// flag that whether cnt_low can be judged

	


  

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


  // generate divided clock at 16
  always @(posedge Bus2IP_Clk)
  begin
	if(Bus2IP_Reset) // reset
	begin
		clk_div_16 <= 1'b0;
		clk_div_cnt <= 16'b0;
	end
	else if(clk_div_cnt == 16'd1406) // reverse div_clock
	begin
		clk_div_16 <= ~clk_div_16;
		clk_div_cnt <= 16'b0;
	end
	else	// count up 
		clk_div_cnt <= clk_div_cnt + 1'b1;
  end
  
 
  // save Bus2IP_Data previous state 
  always @(posedge Bus2IP_Clk)
  begin
	if(Bus2IP_Reset) 
	begin  // reset
		current_state <= 1'b1;
		previous_state <= 1'b1;
	end
	else
	begin  // avoid metastable state
		input_state <= IR_signal; 
		current_state <= input_state;
		previous_state <= current_state;
	end
  end

  // IR_signal state
  always @(posedge Bus2IP_Clk)
  begin
	if(Bus2IP_Reset)
	begin
		state <= high;	//initial
	end
	else if(~previous_state && ~current_state) //0 --> 0
	begin
		state <= low;
		rd_flag <= 1'b1;// cnt_low can count
	end
	else if(previous_state && current_state)   // 1 --> 1
	begin
		state <= high;
		rd_flag <= 1'b0;// cnt_low cannot count
	end
	else if(~previous_state && current_state) //0 --> 1
	begin
		state <= rise;
		rd_flag <= 1'b0;// cnt_low cannot count
	end
	else if(previous_state && ~current_state) //1 --> 0
	begin
		state <= fall;
		rd_flag <= 1'b1;// cnt_low can count
	end
	else 
		state <= state;
  end	
  
  // main
  always @(posedge clk_div_16)
  begin
	if(rd_flag)
		
		cnt_low <= cnt_low + 1;	
	else	
		cnt_low <= 0;
		
	if(state == low)
		data_write_flag <= 1;  	// indicate there is low state before the high state
					// and the cnt_low is ready to write
	else if(state == high)
	begin
		if((cnt_low > 62) && (cnt_low < 66)) // 'start' signal
		begin
			data_bit <= 4'b0;  	// initialize data_bit
			data <= 12'b0;		// initialize data	
			cnt_low <= 0;		// initialize cnt_low
			start_flag <= 1; 	// indicate we have a start signal
		end
		if((cnt_low > 30) && (cnt_low < 34) && data_write_flag && start_flag)
		begin   // signal '1'
			data <= {1'b1,data[11:1]};  // write '1'
			data_bit <= data_bit + 1;   // data_bit count up 
			data_write_flag <= 0;       // finish write, set flag to zero
			cnt_low <= 0;               // finish write, set counter to zero
			send_flag <= 0;             // not yet be sent, set send flag to zero
		end
		if((cnt_low > 14) && (cnt_low < 18) && data_write_flag && start_flag)
		begin   // signal '0'
			data <= {1'b0,data[11:1]};  // write '0'
			data_bit <= data_bit + 1;   // data_bit count up 
			data_write_flag <= 0;       // finish write, set flag to zero
			cnt_low <= 0;               // finish write, set counter to zero
			send_flag <= 0;             // not yet be sent, set send flag to zero
		end

	end
   	//send data and slv_reg1 increase by 1
	if(data_bit == 12 && send_flag == 0)
	begin
		slv_reg0 <= data;
		slv_reg1 <= slv_reg1 + 1'b1;
		send_flag <= 1; // data has been sent, set to 1
		start_flag <= 0;// data has been sent, no 
	end

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
