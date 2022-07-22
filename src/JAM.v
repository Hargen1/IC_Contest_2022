module JAM (
			input CLK,
			input RST,
			output reg [2:0] W,
			output reg [2:0] J,
			input [6:0] Cost,
			output reg [3:0] MatchCount,
			output reg [9:0] MinCost,
			output reg Valid 
			);

reg [2:0] J_data[0:7];
reg [2:0] count;
reg flag;
reg [2:0] ex_value;
reg [2:0] sort[0:7];
reg [2:0] ex_pos;
reg [2:0] exed_pos;
reg [2:0] exed_value;
reg [1:0] op;
reg [9:0] min;
reg [3:0] cost_cnt;
reg en;

integer i;

always @(posedge CLK or posedge RST) begin
	if (RST) begin
		W <= 7;
	end
	else begin
		if (W == 7) begin
			W <= (flag == 1)? ( W + 1 ) : W;
		end
		else begin
			W <= W + 1;
		end
	end
end

always @(*) begin
	J = J_data[W];
end

// J of sorted data
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		for(i = 0; i < 8; i = i+1) begin
			J_data[i] <= i;
		end
	end
	else begin
		if (W == 7) begin
			for(i = 0; i < 8; i = i+1) begin
				J_data[i] <= sort[i];
			end
		end
		else begin
			for(i = 0; i < 8; i = i+1) begin
				J_data[i] <= J_data[i];
			end
		end
	end
end

// seqence 7,6,5,4,3,2,1,0 to 0,1,2,3,4,5,6,7
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		for(i = 0; i < 8; i = i+1) begin
			sort[i] <= 7 - i;
		end
	end
	else begin
		case(op)
			2: begin
				if(flag == 1) begin
					for(i = 0; i < 8; i = i+1) begin
						sort[i] <= sort[i];
					end
				end
				else begin
					sort[ex_pos] <= sort[exed_pos];
					sort[exed_pos] <= sort[ex_pos];
				end
			end
			3: begin
				if(flag == 1) begin
					for(i = 0; i < 8; i = i+1) begin
						sort[i] <= sort[i];
					end
				end
				else begin
					sort[count] <= sort[ex_pos - count - 1];
					sort[ex_pos - count - 1] <= sort[count];
				end
			end
			default: begin
				for(i = 0; i < 8; i = i+1) begin
					sort[i] <= sort[i];
				end
			end
		endcase
	end
end

always @(posedge CLK or posedge RST) begin
	if (RST) begin
		count <= 0;
	end
	else begin
		case(op)
			0: count <= 0;
			1: count <= count + 1;
			2: count <= 0;
			3: count <= (count == ( ex_pos ) >> 1 )? count : count + 1;
		endcase
	end
end

// op 0: search exchange pos
// op 1: search exchanged pos
// op 2: exchange operation
// op 3: reflect
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		op <= 0;
	end
	else begin
		case(op)
			0: begin
				if(W == 0) begin
					op <= op;
				end
				else begin
					if (sort[W - 1] == sort[W] + 1) begin
						op <= (flag == 1)? op : 2;
					end
					else begin
						if (sort[W - 1] > sort[W]) begin
							op <= (flag == 1)? op : 1;
						end
						else begin
							op <= op;
						end
					end
				end
			end
			1: begin
				if(ex_value + 1 == sort[count]) begin
					op <= 2;
				end
				else begin
					if (count + 1 == ex_pos) begin
						op <= 2;
					end
					else begin
						op <= op;
					end
				end
			end
			2: begin
				if (ex_pos == 1) begin
					op <= (W == 7)? 0 : op;
				end
				else begin
					op <= 3;
				end
			end
			3: begin
				if (count == ( ex_pos ) >> 1) begin
					op <= (W == 7)? 0 : op;
				end
				else begin
					op <= 3;
				end
			end
			default: op <= op;
		endcase
	end
end

always @(posedge CLK or posedge RST) begin
	if (RST) begin
		ex_pos <= 0;
		ex_value <= 0;
	end
	else begin
		if (W == 7 && flag == 1) begin
			ex_pos <= 0;
			ex_value <= 0; 
		end
		else begin
			if (sort[W - 1] > sort[W]) begin
				ex_pos <= (op == 0)? W : ex_pos;
				ex_value <= (op == 0)? sort[W] : ex_value;
			end
			else begin
				ex_pos <= ex_pos;
				ex_value <= ex_value;
			end
		end
	end
end

always @(posedge CLK or posedge RST) begin
	if (RST) begin
		exed_pos <= 0;
		exed_value <= 7;
	end
	else begin
		case(op)
			0: begin
				exed_pos <= W - 1;
				exed_value <= sort[W - 1];
			end
			1: begin
				if (ex_value + 1 == sort[count]) begin
					exed_pos <= count;
					exed_value <= sort[count];
				end
				else begin
					if (sort[count] < exed_value) begin
						exed_pos <= (sort[count] < ex_value)? exed_pos : count;
						exed_value <= (sort[count] < ex_value)? exed_value : sort[count];
					end
					else begin
						exed_pos <= exed_pos;
						exed_value <= exed_value;
					end
				end
			end
			default: begin
				exed_pos <= exed_pos;
				exed_value <= exed_value;
			end
		endcase
	end
end

// flag = 1 when operation done
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		flag <= 1;
	end
	else begin
		if (W == 7 && flag == 1) begin
			flag <= 0;
		end
		else begin
			case(op)
				2: begin
					if (ex_pos == 1) begin
						flag <= 1;
					end
					else begin
						flag <= flag;
					end
				end
				3: begin
					if (count + 1 == ( ex_pos ) >> 1) begin
						flag <= 1;
					end
					else begin
						flag <= flag;
					end
				end
				default: flag <= flag;
			endcase
		end	
	end
end

// control MinCost & MatchCount
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		cost_cnt <= 7;
	end
	else begin
		if (en) begin
			cost_cnt <= cost_cnt + 1;
		end
		else begin
			cost_cnt <= 0;
		end
	end
end

// enable for W, J
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		en <= 0;
	end
	else begin
		if (W == 6) begin
			en <= 1;
		end
		else begin
			en <= (W == 1)? 0 : en;
		end
	end
end

// sum of one seqence data
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		min <= 0;
	end
	else begin
		if (en == 1 && W == 1) begin
			min <= Cost;
		end
		else begin
			if(en == 0 && W == 0 && J == 7) min <= 0;
			else min <= min + Cost;
		end
	end
end

always @(posedge CLK or posedge RST) begin
	if (RST) begin
		MinCost <= 10'd1023;
	end
	else begin
		MinCost <= (cost_cnt == 2)? ( ( min < MinCost )? min : MinCost ) : MinCost;
	end
end

always @(posedge CLK or posedge RST) begin
	if (RST) begin
		MatchCount <= 0;
	end
	else begin
		if (cost_cnt == 2) begin
			if (min == MinCost) begin
				MatchCount <= MatchCount + 1;
			end
			else begin
				MatchCount <= (min < MinCost)? 1 : MatchCount;
			end
		end
		else begin
			MatchCount <= MatchCount;
		end
	end
end

// output valid
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		Valid <= 0;
	end
	else begin
		if (cost_cnt == 4'hf) begin
			Valid <= 1;
		end
		else begin
			Valid <= 0;
		end
	end
end

endmodule


