///////////////////////////////////////////////////////////////////////////////
// Description: SPI (Serial Peripheral Interface) Slave
// Creates slave based on input configuration.
// Receives a byte one bit at a time on MOSI
// Will also push out byte data one bit at a time on MISO.
// Any data on input byte will be shipped out on MISO.
// Supports multiple bytes per transaction when CS_n is kept
// low during the transaction.
//
// Note: i_Clk must be at least 4x faster than i_SPI_Clk
// MISO is tri-stated when not communicating. Allows for multiple
// SPI Slaves on the same interface.
//
// Parameters: SPI_MODE, can be 0, 1, 2, or 3. See above.
// Can be configured in one of 4 modes:
// Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
// 0 | 0 | 0
// 1 | 0 | 1
// 2 | 1 | 0
// 3 | 1 | 1
// More info: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
///////////////////////////////////////////////////////////////////////////////

module SPI_Slave #(parameter CLKS_PER_BIT = 104) (
	// Control/Data Signals,
	input i_Rst_L, // FPGA Reset
	input i_Clk, // FPGA Clock
	output reg o_RX_DV, // Data Valid pulse (1 clock cycle)
	output reg [7:0] o_RX_Byte, // Byte received on MOSI
	output reg o_TX_sent, // Pulse when byte TX done
	// input i_TX_DV, // Data Valid pulse to register i_TX_Byte
	// input [7:0] i_TX_Byte, // Byte to serialize to MISO.
	//input i_Tx_DV, // push for data
	output o_Tx_Active,
	//output reg o_Tx_Serial,
	output o_Tx_Done,
	
	output pulses,
	output pulsesx,
	output pulsesy,
	output pin1,
	output pin2,
	output pin1x,
	output pin2x,
	output pin1y,
	output pin2y,
	input ESTOP,
	input dead_end,
	input dead_endx,
	input dead_endy,
	// SPI Interface
	input i_SPI_Clk,
	output o_SPI_MISO,
	input i_SPI_MOSI,
	input i_SPI_CS_n,
	output reg [7:0] LED
);

wire i_TX_DV;
wire [7:0] i_TX_Byte;
// SPI Interface (All Runs at SPI Clock Domain)
wire w_CPOL; // Clock polarity
wire w_CPHA; // Clock phase
wire w_SPI_CLK; // Inverted/non-inverted depending on settings
wire w_SPI_MISO_Mux;

reg [95:0] data_out = 0;

//assign LED = data_out[7:0];

reg flag = 0;
reg [3:0] data_check = 4'b0000;
reg [7:0] first8 = 0;
reg [7:0] second8 = 0;
reg [7:0] third8 = 0;
reg [7:0] fourth8 = 0;
reg [7:0] fifth8 = 0;
reg [7:0] sixth8 = 0;
reg [7:0] seventh8 = 0;
reg [7:0] eightth8 = 0;
reg [7:0] nineth8 = 0;
reg [7:0] tenth8 = 0;
reg [7:0] elevnth8 = 0;
reg [7:0] twelveth8 = 0;
reg [2:0] r_RX_Bit_Count;
reg [2:0] r_TX_Bit_Count;
reg [2:0] old_r_TX_Bit_Count;
reg [7:0] r_Temp_RX_Byte;
reg [7:0] r_RX_Byte;
reg r_RX_Done, r2_RX_Done, r3_RX_Done;
reg [7:0] r_TX_Byte;
reg r_SPI_MISO_Bit, r_Preload_MISO;

parameter SPI_MODE = 0;

//reg [2:0] r_SM_Main = 0;
//reg [15:0] r_Clock_Count = 0;
//reg [3:0] r_Bit_Index = 0;
//reg [7:0] r_Tx_Data = 0;
reg r_Tx_Done = 0;
reg r_Tx_Active = 0;

/*ila_0 myila(.clk(i_Clk),.probe0(o_SPI_MISO),.probe1(r_Temp_RX_Byte),.probe2(r_RX_Byte),.probe3(i_TX_Byte),
.probe4(r_TX_Byte), .probe5(i_TX_Byte),.probe6(old_r_TX_Bit_Count),.probe7(r_TX_Bit_Count),
.probe8(i_Rst_L),.probe9(r_RX_Byte),.probe10(i_SPI_Clk),.probe11(i_SPI_MOSI),.probe12(i_SPI_CS_n),
.probe13(r_RX_Done),.probe14(r2_RX_Done),.probe15(r3_RX_Done),
.probe16(o_RX_DV),.probe17(i_TX_DV),.probe18(r_RX_Done),.probe19(o_TX_sent));
*/
// CPOL: Clock Polarity
// CPOL=0 means clock idles at 0, leading edge is rising edge.
// CPOL=1 means clock idles at 1, leading edge is falling edge.
assign w_CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);

// CPHA: Clock Phase
// CPHA=0 means the "out" side changes the data on trailing edge of clock
// the "in" side captures data on leading edge of clock
// CPHA=1 means the "out" side changes the data on leading edge of clock
// the "in" side captures data on the trailing edge of clock
assign w_CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);

assign w_SPI_CLK = w_CPHA ? ~i_SPI_Clk : i_SPI_Clk;

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		data_out <= 0;
	end else begin
		if(flag) begin
			data_out <= {first8,second8,third8,fourth8,fifth8,sixth8,seventh8,eightth8,nineth8,tenth8,elevnth8,twelveth8};
			LED <= data_out[7:0];
		end else begin
			data_out <= data_out;
		end
	end
end

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		flag <= 1'b0;
		data_check <= 2'b00;
		first8 <= 0;
		second8 <= 0;
		third8 <= 0;
		fourth8 <= 0;
		fifth8 <= 0;
		sixth8 <= 0;
		seventh8 <= 0;
		eightth8 <= 0;
		nineth8 <= 0;
		tenth8 <= 0;
		elevnth8 <= 0;
		twelveth8 <= 0;
	end else begin
		if(r3_RX_Done == 1'b0 && r2_RX_Done == 1'b1) begin

			if(data_check == 4'b1011) begin
				twelveth8 <= r_RX_Byte;
				flag <= 1'b1;
				data_check <= 4'b0000;
			end

			if(data_check == 4'b1010) begin
				elevnth8 <= r_RX_Byte;
				data_check <= 4'b1011;
			end

			if(data_check == 4'b1001) begin
				tenth8 <= r_RX_Byte;
				data_check <= 4'b1010;
			end

			if(data_check == 4'b1000) begin
				nineth8 <= r_RX_Byte;
				data_check <= 4'b1001;
			end

			if(data_check == 4'b0111) begin
				eightth8 <= r_RX_Byte;
				data_check <= 4'b1000;
			end

			if(data_check == 4'b0110) begin
				seventh8 <= r_RX_Byte;
				data_check <= 4'b0111;
			end

			if(data_check == 4'b0101) begin
				sixth8 <= r_RX_Byte;
				data_check <= 4'b0110;
			end

			if(data_check == 4'b0100) begin
				fifth8 <= r_RX_Byte;
				data_check <= 4'b0101;
			end

			if(data_check == 4'b0011) begin
				fourth8 <= r_RX_Byte;
				data_check <= 4'b0100;
			end

			if(data_check == 4'b0010) begin
				third8 <= r_RX_Byte;
				data_check <= 4'b0011;
			end

			if(data_check == 4'b0001) begin
				second8 <= r_RX_Byte;
				data_check <= 4'b0010;
			end

			if(data_check == 4'b0000) begin
				first8 <= r_RX_Byte;
				flag <= 1'b0;
				data_check <= 4'b0001;
			end
		end
	end
end

// Purpose: Recover SPI Byte in SPI Clock Domain
// Samples line on correct edge of SPI Clock
always @(posedge w_SPI_CLK or posedge i_SPI_CS_n) begin
	if (i_SPI_CS_n) begin
		r_RX_Bit_Count <= 0;
		r_RX_Done <= 1'b0;
	end else begin
		r_RX_Bit_Count <= r_RX_Bit_Count + 1;

		// Receive in LSB, shift up to MSB
		r_Temp_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};

		if (r_RX_Bit_Count == 3'b111) begin
			r_RX_Done <= 1'b1;
			r_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};
		end else if (r_RX_Bit_Count == 3'b010) begin
			r_RX_Done <= 1'b0;
		end
	end // else: !if(i_SPI_CS_n)
end // always @ (posedge w_SPI_Clk or posedge i_SPI_CS_n)

// Purpose: Cross from SPI Clock Domain to main FPGA clock domain
// Assert o_RX_DV for 1 clock cycle when o_RX_Byte has valid data.
always @(posedge i_Clk or negedge i_Rst_L) begin
	if (~i_Rst_L) begin
		r2_RX_Done <= 1'b0;
		r3_RX_Done <= 1'b0;
		o_RX_DV <= 1'b0;
		o_RX_Byte <= 8'h00;
	end else begin
		// Here is where clock domains are crossed.
		// This will require timing constraint created, can set up long path.
		r2_RX_Done <= r_RX_Done;
		r3_RX_Done <= r2_RX_Done;

		if (r3_RX_Done == 1'b0 && r2_RX_Done == 1'b1) begin // rising edge
			o_RX_DV <= 1'b1; // Pulse Data Valid 1 clock cycle
			o_RX_Byte <= r_RX_Byte;
		end else begin
			o_RX_DV <= 1'b0;
		end
	end // else: !if(~i_Rst_L)
end // always @ (posedge i_Bus_Clk)

// Control preload signal. Should be 1 when CS is high, but as soon as
// first clock edge is seen it goes low.
always @(posedge w_SPI_CLK or posedge i_SPI_CS_n) begin
	if (i_SPI_CS_n) begin
		r_Preload_MISO <= 1'b1;
	end else begin
		r_Preload_MISO <= 1'b0;
	end
end

// Purpose: Transmits 1 SPI Byte whenever SPI clock is toggling
// Will transmit read data back to SW over MISO line.
// Want to put data on the line immediately when CS goes low.
always @(posedge w_SPI_CLK or posedge i_SPI_CS_n) begin
	if (i_SPI_CS_n) begin
		r_TX_Bit_Count <= 3'b111; // Send MSb first
		r_SPI_MISO_Bit <= r_TX_Byte[3'b111]; // Reset to MSb
	end else begin
		r_TX_Bit_Count <= r_TX_Bit_Count - 1;

		// Here is where data crosses clock domains from i_Clk to w_SPI_Clk
		// Can set up a timing constraint with wide margin for data path.
		r_SPI_MISO_Bit <= r_TX_Byte[r_TX_Bit_Count];
	end // else: !if(i_SPI_CS_n)
end // always @ (negedge w_SPI_Clk or posedge i_SPI_CS_n_SW)


// Purpose: Register TX Byte when DV pulse comes. Keeps registed byte in
// this module to get serialized and sent back to master.
always @(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		old_r_TX_Bit_Count <= 0;
	end else begin
		old_r_TX_Bit_Count<=r_TX_Bit_Count;

		if((old_r_TX_Bit_Count==1)&&(r_TX_Bit_Count==0)) begin
			o_TX_sent<=1'b1;
		end else begin
			o_TX_sent<=1'b0;
		end

		if (i_Rst_L || (r_TX_Bit_Count==0 && w_SPI_CLK) && ~i_TX_DV) begin // Will remove message on send
			r_TX_Byte <= 8'h00;
		end else begin // if (i_Rst_L || (r_TX_Bit_Count==0 && w_SPI_CLK))
			if (i_TX_DV) begin
				r_TX_Byte <= i_TX_Byte;
			end
		end // else: !if(~i_Rst_L)
	end
end // always @ (posedge i_Clk or negedge i_Rst_L)




// Preload MISO with top bit of send data when preload selector is high.
// Otherwise just send the normal MISO data
assign w_SPI_MISO_Mux = r_Preload_MISO ? r_TX_Byte[3'b111] : r_SPI_MISO_Bit;
assign i_TX_DV = o_RX_DV;
assign i_TX_Byte = o_RX_Byte;

// Tri-statae MISO when CS is high. Allows for multiple slaves to talk.
assign o_SPI_MISO = i_SPI_CS_n ? 1'bZ : w_SPI_MISO_Mux;



assign o_Tx_Active = r_Tx_Active;
assign o_Tx_Done = r_Tx_Done;

bfg bfg_inst (
	.i_Rst_L  (i_Rst_L), 
	.i_Clk    (i_Clk),
	.pulses   (pulses),
	.pulsesx  (pulsesx),
	.pulsesy  (pulsesy),
	.pin1     (pin1),
	.pin2     (pin2),
	.pin1x    (pin1x),
	.pin2x    (pin2x),
	.pin1y    (pin1y),
	.pin2y    (pin2y),
	.ESTOP    (ESTOP),
	.dead_end (dead_end),
	.dead_endx(dead_endx),
	.dead_endy(dead_endy),
	.data_out (data_out)
);

endmodule // SPI_Slave
