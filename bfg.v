`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:17:08 09/12/2023 
// Design Name: 
// Module Name:    bfg 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module bfg(
	input i_Rst_L, // FPGA Reset
	input i_Clk,
	output reg pulses,
	output reg pulsesx,
	output reg pulsesy,
	output reg pin1,
	output reg pin2,
	output reg pin1x,
	output reg pin2x,
	output reg pin1y,
	output reg pin2y,
	input ESTOP,
	input dead_end,
	input dead_endx,
	input dead_endy,
	input [95:0] data_out
    );

reg [15:0] pulse_rate = 200;
reg stopp = 0;

//for z axis
reg stop =0;
reg [31:0] cnt = 0;
wire [31:0] dist1;
reg [31:0] dist2 = 0;
reg [31:0] dist3 = 0;
reg [23:0] int_rpm;
reg [15:0] rpm = 40;
reg [15:0] dist = 0;
reg [23:0] counter = 0;
reg toggle = 1;
wire [23:0] store;

//for x axis
reg stopx =0;
reg [31:0] cntx = 0;
wire [31:0] dist1x;
reg [31:0] dist2x = 0;
reg [31:0] dist3x = 0;
reg [23:0] int_rpmx;
reg [15:0] rpmx = 40;
reg [15:0] distx = 0;
reg [23:0] counterx = 0;
reg togglex = 1;
wire [23:0] storex;

//for y axis
reg stopy =0;
reg [31:0] cnty = 0;
wire [31:0] dist1y;
reg [31:0] dist2y = 0;
reg [31:0] dist3y = 0;
reg [23:0] int_rpmy;
reg [15:0] rpmy = 40;
reg [15:0] disty = 0;
reg [23:0] countery = 0;
reg toggley = 1;
wire [23:0] storey;

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		stopp <= 0;
	end else begin
		if(ESTOP) begin
			stopp <= 1;
		end else begin
			stopp <= stopp;
		end
	end
end

/////////////////////////////////////////////////////////////////////////////
///                           for z axis                                 ////
/////////////////////////////////////////////////////////////////////////////

assign store = ((3600000)/int_rpm);
assign dist1 = ((pulse_rate/5)*dist);

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		int_rpm <= 250;
		cnt <= 0;
	end else begin
                if (cnt > (11999999/2)) begin
	        	if (int_rpm < (rpm-40) && dist2 < (dist1 - dist3)) begin
	        		if (int_rpm > 1160) begin
	        			int_rpm <= 1200;
	        		end else begin
	        			int_rpm <= int_rpm + 40;
	        		end
	        	end else if (dist2 < (dist1 - dist3)) begin
	        		  if(int_rpm > (rpm+40)) begin
	        			  int_rpm <= int_rpm - 40;
	        		  end else begin
	        			if (rpm > 1200) begin
	        				int_rpm <= 1200;
	        			end else begin
	        				int_rpm <= rpm;
	        			end
	        		  end
	         	end else if (dist2 < dist1) begin
	        		if(dead_end) begin
	        			int_rpm <= int_rpm - 40;
	        	        end else begin
	        			int_rpm <= rpm;
	        		end
	        	end else begin
	        		int_rpm <= 250;
	        	end

	        	cnt <= 0;

	        end else begin
	        	cnt <= cnt + 1;
	        end
	end
end

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		stop = 0; // issue
		dist <= 0;
		rpm <= 0;
		dist2 <= 0;
		dist3 <= 0;
		pulses <= 0;
		counter <= 0;
	end else begin
	        if (stop == 0 && stopp == 0) begin

                        if(dist2 == 0)  begin
	        		dist <= data_out[31:16];
	        		rpm <= data_out[15:0];

	        		if (data_out[31] == 1) begin
	        			pin1 <= 0;
	        			pin2 <= 1;
	        		end else begin
	        			pin1 <= 1;
	        			pin2 <= 0;
	        		end

	        	end else begin
	        		dist <= dist;
	        		rpm <= rpm;
                        end

                        if(dist > 0) begin
								counter <= counter + 1;
	        		if (counter > store) begin
	        			toggle <= ~toggle;
	        			counter <= 0;

	        			if (dist2 > dist1) begin
	        				// int_rpm <= 0; // 250
	        				dist2 <= 0;

	        				if (dead_end) begin
	        					stop = 1;
	        				end

	        			end else begin
                                                dist2 <= dist2 + 1;
                                                if (int_rpm <= (rpm - 40)) begin
	        					dist3 <= dist2;
                                                end else begin
	        					dist3 <= dist3;
                                                end
	        			end
	        		end else begin
	        			
	        			pulses <= toggle; // pulses insted of toggle if not worked copy line no 366;

	        			if(data_out == 0) begin
	        				stop = 0;
	        			end
	        		end
	        	end
	        end
	end
end

/////////////////////////////////////////////////////////////////////////////
///                           for x axis                                 ////
/////////////////////////////////////////////////////////////////////////////

assign storex = ((3600000)/int_rpmx);
assign dist1x = ((pulse_rate/5)*distx);

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		int_rpmx <= 250;
		cntx <= 0;
	end else begin
                if (cntx > (11999999/2)) begin
	        	if (int_rpmx < (rpmx-40) && dist2x < (dist1x - dist3x)) begin
	        		if (int_rpmx > 1160) begin
	        			int_rpmx <= 1200;
	        		end else begin
	        			int_rpmx <= int_rpmx + 40;
	        		end
	        	end else if (dist2x < (dist1x - dist3x)) begin
	        		  if(int_rpmx > (rpmx+40)) begin
	        			  int_rpmx <= int_rpmx - 40;
	        		  end else begin
	        			if (rpmx > 1200) begin
	        				int_rpmx <= 1200;
	        			end else begin
	        				int_rpmx <= rpmx;
	        			end
	        		  end
	         	end else if (dist2x < dist1x) begin
	        		if(dead_endx) begin
	        			int_rpmx <= int_rpmx - 40;
	        	        end else begin
	        			int_rpmx <= rpmx;
	        		end
	        	end else begin
	        		int_rpmx <= 250;
	        	end

	        	cntx <= 0;

	        end else begin
	        	cntx <= cntx + 1;
	        end
	end
end

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		stopx = 0; // issue
		distx <= 0;
		rpmx <= 0;
		dist2x <= 0;
		dist3x <= 0;
		pulsesx <= 0;
		counterx <= 0;
	end else begin
	        if (stopx == 0 && stopp == 0) begin

                        if(dist2x == 0)  begin
	        		distx <= data_out[63:48];
	        		rpmx <= data_out[47:32];

	        		if (data_out[63] == 1) begin
	        			pin1x <= 0;
	        			pin2x <= 1;
	        		end else begin
	        			pin1x <= 1;
	        			pin2x <= 0;
	        		end

	        	end else begin
	        		distx <= distx;
	        		rpmx <= rpmx;
                        end

                        if(distx > 0) begin
								counterx <= counterx + 1;
	        		if (counterx > storex) begin
	        			togglex <= ~togglex;
	        			counterx <= 0;

	        			if (dist2x > dist1x) begin
	        				// int_rpm <= 0; // 250
	        				dist2x <= 0;

	        				if (dead_endx) begin
	        					stopx = 1;
	        				end

	        			end else begin
                                                dist2x <= dist2x + 1;
                                                if (int_rpmx <= (rpmx - 40)) begin
	        					dist3x <= dist2x;
                                                end else begin
	        					dist3x <= dist3x;
                                                end
	        			end
	        		end else begin
	        			
	        			pulsesx <= togglex; // pulses instead of togglex if not worked copy line no 366;

	        			if(data_out == 0) begin
	        				stopx = 0;
	        			end
	        		end
	        	end
	        end
	end
end

/////////////////////////////////////////////////////////////////////////////
///                           for y axis                                 ////
/////////////////////////////////////////////////////////////////////////////

assign storey = ((3600000)/int_rpmy);
assign dist1y = ((pulse_rate/5)*disty);

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		int_rpmy <= 250;
		cnty <= 0;
	end else begin
                if (cnty > (11999999/2)) begin
	        	if (int_rpmy < (rpmy-40) && dist2y < (dist1y - dist3y)) begin
	        		if (int_rpmy > 1160) begin
	        			int_rpmy <= 1200;
	        		end else begin
	        			int_rpmy <= int_rpmy + 40;
	        		end
	        	end else if (dist2y < (dist1y - dist3y)) begin
	        		  if(int_rpmy > (rpmy+40)) begin
	        			  int_rpmy <= int_rpmy - 40;
	        		  end else begin
	        			if (rpmy > 1200) begin
	        				int_rpmy <= 1200;
	        			end else begin
	        				int_rpmy <= rpmy;
	        			end
	        		  end
	         	end else if (dist2y < dist1y) begin
	        		if(dead_endy) begin
	        			int_rpmy <= int_rpmy - 40;
	        	        end else begin
	        			int_rpmy <= rpmy;
	        		end
	        	end else begin
	        		int_rpmy <= 250;
	        	end

	        	cnty <= 0;

	        end else begin
	        	cnty <= cnty + 1;
	        end
	end
end

always@(posedge i_Clk or negedge i_Rst_L) begin
	if(!i_Rst_L) begin
		stopy = 0; // issue
		disty <= 0;
		rpmy <= 0;
		dist2y <= 0;
		dist3y <= 0;
		pulsesy <= 0;
		countery <= 0;
	end else begin
	        if (stopy == 0 && stopp == 0) begin

                        if(dist2y == 0)  begin
	        		disty <= data_out[95:80];
	        		rpmy <= data_out[79:64];

	        		if (data_out[95] == 1) begin
	        			pin1y <= 0;
	        			pin2y <= 1;
	        		end else begin
	        			pin1y <= 1;
	        			pin2y <= 0;
	        		end

	        	end else begin
	        		disty <= disty;
	        		rpmy <= rpmy;
                        end

                        if(disty > 0) begin
								countery <= countery + 1;
	        		if (countery > storey) begin
	        			toggley <= ~toggley;
	        			countery <= 0;

	        			if (dist2y > dist1y) begin
	        				// int_rpm <= 0; // 250
	        				dist2y <= 0;

	        				if (dead_endy) begin
	        					stopy = 1;
	        				end

	        			end else begin
                                                dist2y <= dist2y + 1;
                                                if (int_rpmy <= (rpmy - 40)) begin
	        					dist3y <= dist2y;
                                                end else begin
	        					dist3y <= dist3y;
                                                end
	        			end
	        		end else begin
	        			
	        			pulsesy <= toggley; // pulses insted of toggley if not worked copy line no 366;

	        			if(data_out == 0) begin
	        				stopy = 0;
	        			end
	        		end
	        	end
	        end
	end
end


endmodule
