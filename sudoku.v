// WIP highly parallel sudoku solver in verilog
// TODO: implement more set methods, and a way to merge them (ex: if this cell is the onyl cell in a region that can be X, set this cell to X)
// TODO: consider how to implement recursive guess-and-check (bram required, probably)
// TODO: consider input/output interfaces (UART?)

module sudoku ();
    reg clk_r = 1;
    reg clk_en = 0;
    wire clk = clk_r & clk_en;
    always #0.5 clk_r = ~clk_r;
    initial #1 clk_en = 1;
    
	localparam SIZE=4, SIZE_SQRT=2;
	reg [SIZE-1:0] _cells [SIZE-1:0][SIZE-1:0];
	reg [SIZE-1:0] done [SIZE-1:0][SIZE-1:0];
	initial begin
	    // puzzle:           (32'h) 1FF8 F81F F48F 8FF4
	    // expected results: (32'h) 1248 4812 2481 8124
	    // tested results:   (32'h) 1248 4812 2481 8124
		_cells[0][0] = 4'b0001;
		_cells[0][1] = 4'b1111;
		_cells[0][2] = 4'b1111;
		_cells[0][3] = 4'b1000;
		_cells[1][0] = 4'b1111;
		_cells[1][1] = 4'b1000;
		_cells[1][2] = 4'b0001;
		_cells[1][3] = 4'b1111;
		_cells[2][0] = 4'b1111;
		_cells[2][1] = 4'b0100;
		_cells[2][2] = 4'b1000;
		_cells[2][3] = 4'b1111;
		_cells[3][0] = 4'b1000;
		_cells[3][1] = 4'b1111;
		_cells[3][2] = 4'b1111;
		_cells[3][3] = 4'b0100;
	end
	
	// 1 . . 4 = 1 2 3 4
	// . 4 1 . = 3 4 1 2
	// . 3 4 . = 2 3 4 1
	// 4 . . 3 = 4 1 2 3
	
	genvar g_done_x, g_done_y;
	generate
		for (g_done_y=0; g_done_y<SIZE; g_done_y=g_done_y+1) begin : generate_done_y
			for (g_done_x=0; g_done_x<SIZE; g_done_x=g_done_x+1) begin : generate_done_x
				always@(_cells[g_done_y][g_done_x]) begin
					case (_cells[g_done_y][g_done_x])
						4'b0001: done[g_done_y][g_done_x] = 4'b0001;
						4'b0010: done[g_done_y][g_done_x] = 4'b0010;
						4'b0100: done[g_done_y][g_done_x] = 4'b0100;
						4'b1000: done[g_done_y][g_done_x] = 4'b1000;
						default: done[g_done_y][g_done_x] = 4'b0000;
					endcase
				end
			end
		end
	endgenerate
	wire [3:0] region_row [3:0];
	wire [3:0] region_box [3:0];
	wire [3:0] region_col [3:0];
	genvar g_row;
	generate
		for (g_row=0; g_row<SIZE; g_row=g_row+1) begin : generate_row
			assign region_row[g_row] = done[g_row][0] | done[g_row][1] | done[g_row][2] | done[g_row][3];
		end
	endgenerate
	genvar g_box;
	generate
		for (g_box=0; g_box<SIZE; g_box=g_box+1) begin : generate_box
			assign region_box[g_box] = 
			    done[{g_box[1], 1'b0}][{g_box[0], 1'b0}] |
			    done[{g_box[1], 1'b0}][{g_box[0], 1'b1}] |
			    done[{g_box[1], 1'b1}][{g_box[0], 1'b0}] |
			    done[{g_box[1], 1'b1}][{g_box[0], 1'b1}];
		end
	endgenerate
	genvar g_col;
	generate
		for (g_col=0; g_col<SIZE; g_col=g_col+1) begin : generate_col
			assign region_col[g_col] = done[0][g_col] | done[1][g_col] | done[2][g_col] | done[3][g_col];
		end
	endgenerate
	genvar cell_x, cell_y;
	generate
		for (cell_y=0; cell_y<SIZE; cell_y=cell_y+1) begin : generate_cell_y
			for (cell_x=0; cell_x<SIZE; cell_x=cell_x+1) begin : generate_cell_x
				always@(posedge clk) begin
				    if (done[cell_y][cell_x] == 4'b0000)
                        _cells[cell_y][cell_x] <= _cells[cell_y][cell_x] & ~region_row[cell_y] & ~region_box[{cell_y[1], cell_x[1]}] & ~region_col[cell_x];

				end
			end
		end
	endgenerate
	
	initial #10 $finish;
endmodule