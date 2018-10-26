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
	reg [SIZE-1:0] _cells_golden [SIZE-1:0][SIZE-1:0];
	reg [SIZE-1:0] done [SIZE-1:0][SIZE-1:0];
	initial begin
	    // puzzle:           (32'h) 1FF8 F81F F48F 8FF4
	    // expected results: (32'h) 1248 4812 2481 8124
	    // tested results:   (32'h) 1248 4812 2481 8124
		_cells[0][0] = 4'b0001; _cells_golden[0][0] = 4'b0001;
		_cells[0][1] = 4'b1111; _cells_golden[0][1] = 4'b0010;
		_cells[0][2] = 4'b1111; _cells_golden[0][2] = 4'b0100;
		_cells[0][3] = 4'b1000; _cells_golden[0][3] = 4'b1000;
		_cells[1][0] = 4'b1111; _cells_golden[1][0] = 4'b0100;
		_cells[1][1] = 4'b1000; _cells_golden[1][1] = 4'b1000;
		_cells[1][2] = 4'b0001; _cells_golden[1][2] = 4'b0001;
		_cells[1][3] = 4'b1111; _cells_golden[1][3] = 4'b0010;
		_cells[2][0] = 4'b1111; _cells_golden[2][0] = 4'b0010;
		_cells[2][1] = 4'b0100; _cells_golden[2][1] = 4'b0100;
		_cells[2][2] = 4'b1000; _cells_golden[2][2] = 4'b1000;
		_cells[2][3] = 4'b1111; _cells_golden[2][3] = 4'b0001;
		_cells[3][0] = 4'b1000; _cells_golden[3][0] = 4'b1000;
		_cells[3][1] = 4'b1111; _cells_golden[3][1] = 4'b0001;
		_cells[3][2] = 4'b1111; _cells_golden[3][2] = 4'b0010;
		_cells[3][3] = 4'b0100; _cells_golden[3][3] = 4'b0100;
	end
	reg valid;
	always@(*) begin : check_valid
	    integer y, x;
	    valid = 1;
	    for (y=0; y<SIZE; y=y+1)
	       for (x=0; x<SIZE; x=x+1)
	           if (_cells[y][x] != _cells_golden[y][x])
	               valid = 0;
	end
	// 1 . . 4 = 1 2 3 4
	// . 4 1 . = 3 4 1 2
	// . 3 4 . = 2 3 4 1
	// 4 . . 3 = 4 1 2 3
	
	genvar g_done_x, g_done_y;
	generate
		for (g_done_y=0; g_done_y<SIZE; g_done_y=g_done_y+1) begin : generate_done_y
			for (g_done_x=0; g_done_x<SIZE; g_done_x=g_done_x+1) begin : generate_done_x
				always@(_cells[g_done_y][g_done_x]) begin : generate_done_y_x
				    integer i;
				    done[g_done_y][g_done_x] = 0;
				    for (i=0; i<SIZE; i=i+1)
				        if (_cells[g_done_y][g_done_x] == 1 << i)
				            done[g_done_y][g_done_x] = _cells[g_done_y][g_done_x];
				end
			end
		end
	endgenerate
	reg [SIZE-1:0] region_row [SIZE-1:0];
	reg [SIZE-1:0] region_box [SIZE-1:0];
	reg [SIZE-1:0] region_col [SIZE-1:0];
	genvar region_i;
	generate
		for (region_i=0; region_i<SIZE; region_i=region_i+1) begin : generate_row
		    always@(*) begin : generate_region_row
		        integer i;
		        integer temp_row, temp_col, temp_box;
		        temp_row = 0;
		        temp_col = 0;
		        temp_box = 0;
		        for (i=0; i<SIZE; i=i+1) begin
                    temp_row = temp_row | done[region_i][i];
                    temp_col = temp_col | done[i][region_i];
                    temp_box = temp_box | done[(region_i / SIZE_SQRT) * SIZE_SQRT + (i / SIZE_SQRT)][(region_i % SIZE_SQRT) * SIZE_SQRT + (i % SIZE_SQRT)];
		        end
                region_row[region_i] = temp_row;
                region_col[region_i] = temp_col;
                region_box[region_i] = temp_box;
		    end
		end
	endgenerate
	
	genvar cell_x, cell_y;
	generate
		for (cell_y=0; cell_y<SIZE; cell_y=cell_y+1) begin : generate_cell_y
			for (cell_x=0; cell_x<SIZE; cell_x=cell_x+1) begin : generate_cell_x
				always@(posedge clk) begin
				    if (done[cell_y][cell_x] == 0) begin
                        _cells[cell_y][cell_x] <= _cells[cell_y][cell_x] &
                            ~region_row[cell_y] &
                            ~region_box[ (cell_y / SIZE_SQRT) * SIZE_SQRT + (cell_x / SIZE_SQRT) ] &
                            ~region_col[cell_x];
                    end
				end
			end
		end
	endgenerate
	
	initial #10 $finish;
endmodule