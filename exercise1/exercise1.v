/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module exercise1 (
		input logic CLOCK_I,
		input logic RESETN_I,
		output logic [7:0] READ_DATA_A_O [1:0],
		output logic [7:0] READ_DATA_B_O [1:0]
);

enum logic [1:0] {
	S_READ,
	S_WRITE,
	S_IDLE
} state;

/*
It is requested that (n is 512):

if A[i] is negative
then C[i] = A[i] + B[i] 
else C[i] = A[i] - B[n-1-i]

if B[i] is negative 
then D[i] = B[i] - A[i] 
else D[i] = B[i] + A[n-1-i]

Observe that:

if A[n-1-i] is negative 
then C[n-1-i] = A[n-1-i] + B[n-1-i] 
else C[n-1-i] = A[n-1-i] - B[i]

if B[n-1-i] is negative
then D[n-1-i] = B[n-1-i] - A[n-1-i] 
else D[n-1-i] = B[n-1-i] + A[i]

You can read from the two dual-port memories A[i] and A[n-1-i], as well as B[i] and B[n-1-i], in the same clock cycle; 
in the following clock cycle you can write all four values, i.e., C[i], C[n-1-i], D[i] and D[n-1-i], to the two dual-port memories.
*/

logic [8:0] address_a[1:0];
logic [8:0] address_b[1:0];
logic [7:0] write_data_a [1:0];
logic [7:0] write_data_b [1:0];
logic write_enable_a [1:0];
logic write_enable_b [1:0];
logic [7:0] read_data_a [1:0];
logic [7:0] read_data_b [1:0];

// use the same address for port A for both DP-RAMs
assign address_a[1] = address_a[0];
// use 511 - address_a (or 1s complement of address_a) for port B for both DP-RAMs
assign address_b[0] = ~address_a[0];
assign address_b[1] = ~address_a[0];

// use the same write enable signal for both ports for both DP-RAMs
assign write_enable_b[0] = write_enable_a[0];
assign write_enable_a[1] = write_enable_a[0];
assign write_enable_b[1] = write_enable_a[0];

// Instantiate RAM1
dual_port_RAM1 dual_port_RAM_inst1 (
	.address_a ( address_a[1] ),
	.address_b ( address_b[1] ),
	.clock ( CLOCK_I ),
	.data_a ( write_data_a[1] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_enable_a[1] ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
	);

// Instantiate RAM0
dual_port_RAM0 dual_port_RAM_inst0 (
	.address_a ( address_a[0] ),
	.address_b ( address_b[0] ),
	.clock ( CLOCK_I ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_b[0] ),
	.wren_a ( write_enable_a[0] ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
	);

// implement if A[i] is negative then C[i] = A[i] + B[i], otherwise C[i] = A[i] - B[511-i]
assign write_data_a[0] = read_data_a[0][7] ? read_data_a[0] + read_data_a[1] : read_data_a[0] - read_data_b[1];

// implement if B[i] is negative then D[i] = B[i] - A[i], otherwise D[i] = B[i] + A[511-i]
assign write_data_a[1] = read_data_a[1][7] ? read_data_a[1] - read_data_a[0] : read_data_a[1] + read_data_b[0];

// implement if A[511-i] is negative then C[511-i] = A[511-i] + B[511-i], otherwise C[511-i] = A[511-1] - B[i]
assign write_data_b[0] = read_data_b[0][7] ? read_data_b[0] + read_data_b[1] : read_data_b[0] - read_data_a[1];

// implement if B[511-i] is negative then D[511-i] = B[511-i] - A[511-i], otherwise D[511-i] = B[511-i] + A[i]
assign write_data_b[1] = read_data_b[1][7] ? read_data_b[1] - read_data_b[0] : read_data_b[1] + read_data_a[0];

// FSM to control the read and write sequence
always_ff @ (posedge CLOCK_I or negedge RESETN_I) begin
	if (RESETN_I == 1'b0) begin
		address_a[0] <= 9'd0;
		write_enable_a[0] <= 1'b0;
		state <= S_READ;
	end else begin
		case (state)
		S_IDLE: begin
		end
		S_WRITE: begin	
			state <= S_READ;
			write_enable_a[0] <= 1'b0;
			address_a[0] <= address_a[0] + 9'd1;
			if (address_a[0] == 9'd255)
				  state <= S_IDLE;
		end
		S_READ: begin
			state <= S_WRITE;
			write_enable_a[0] <= 1'b1;
		end
		endcase
	end
end

assign READ_DATA_A_O = read_data_a;
assign READ_DATA_B_O = read_data_b;

endmodule
