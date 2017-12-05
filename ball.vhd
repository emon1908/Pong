library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ball is
port(
		clk, reset : in std_logic;
		pause : in std_logic;
		paddle1_on, paddle2_on : in std_logic;
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		player1_score, player2_score : out std_logic_vector(2 downto 0);
		player_scored : out std_logic;
		ball_on : out std_logic;
		ball_rgb : out std_logic_vector(2 downto 0)
	);
end ball;

architecture ball_arch of ball is

	-- Signal used to control speed of ball and how
	-- often pushbuttons are checked for paddle movement.
	signal refr_tick: std_logic;
	
	-- x, y coordinates (0,0 to (639, 479)
	signal pix_x, pix_y: unsigned(9 downto 0);
	
	-- screen dimensions
	constant MAX_X: integer := 640;
	constant MAX_Y_T: integer := 50;
	constant MAX_Y_B: integer := 430;
	
	-- square ball -- ball left, right, top and bottom
	-- all vary. Left and top driven by registers below.
	constant BALL_SIZE: integer := 8;
	signal ball_x_l, ball_x_r: unsigned(9 downto 0);
	signal ball_y_t, ball_y_b: unsigned(9 downto 0);
	
	-- reg to track left and top boundary
	signal ball_x_reg, ball_x_next: unsigned(9 downto 0);
	signal ball_y_reg, ball_y_next: unsigned(9 downto 0);
	
	-- reg to track ball speed
	signal x_delta_reg, x_delta_next : unsigned(9 downto 0);
	signal y_delta_reg, y_delta_next : unsigned(9 downto 0);
	
	-- ball movement can be pos or neg
	constant BALL_V_P: unsigned(9 downto 0) := to_unsigned(2,10);
	constant BALL_V_N: unsigned(9 downto 0) := unsigned(to_signed(-2,10));
	
	-- round ball image
	type rom_type is array(0 to 7) of std_logic_vector(0 to 7);
	constant BALL_ROM: rom_type:= (
		"00111100",
		"01111110",
		"11111111",
		"11111111",
		"11111111",
		"11111111",
		"01111110",
		"00111100"
	);
	
	signal rom_addr, rom_col: unsigned(2 downto 0);
	signal rom_data: std_logic_vector(7 downto 0);
	signal rom_bit: std_logic;
	
	-- object output signals -- new signal to indicate if
	-- scan coord is within ball
	signal sq_ball_on, rd_ball_on : std_logic;
	-- ====================================================

	signal p1_score_reg, p1_score_next : unsigned(2 downto 0);
	signal p2_score_reg, p2_score_next : unsigned(2 downto 0);
	signal scored : std_logic;

begin

	process (clk, reset)
	begin
		if (reset = '1') then
			ball_x_reg <= "0100111011";
			ball_y_reg <= "0011110000";
			x_delta_reg <= "0000000010";
			y_delta_reg <= "0000000010";
			p1_score_reg <= to_unsigned(0,3);
			p2_score_reg <= to_unsigned(0,3);
		elsif (clk'event and clk = '1') then
			ball_x_reg <= ball_x_next;
			ball_y_reg <= ball_y_next;
			x_delta_reg <= x_delta_next;
			y_delta_reg <= y_delta_next;
			p1_score_reg <= p1_score_next;
			p2_score_reg <= p2_score_next;
		end if;
	end process;
	
	pix_x <= unsigned(pixel_x);
	pix_y <= unsigned(pixel_y);
	
	-- refr_tick: 1-clock tick asserted at start of v_sync,
	-- e.g., when the screen is refreshed -- speed is 60 Hz
	refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) and (pause = '0')else 
					 '0';
	
	-- set coordinates of square ball.
	ball_x_l <= ball_x_reg;
	ball_y_t <= ball_y_reg;
	ball_x_r <= ball_x_l + BALL_SIZE - 1;
	ball_y_b <= ball_y_t + BALL_SIZE - 1;
	
	-- pixel within square ball
	sq_ball_on <= '1' when (ball_x_l <= pix_x) and (pix_x <= ball_x_r) and 
								  (ball_y_t <= pix_y) and (pix_y <= ball_y_b) else 
					  '0';
	
	-- map scan coord to ROM addr/col -- use low order three
	-- bits of pixel and ball positions.
	-- ROM row
	rom_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
	-- ROM column
	rom_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
	-- Get row data
	rom_data <= BALL_ROM(to_integer(rom_addr));
	-- Get column bit
	rom_bit <= rom_data(to_integer(rom_col));
	
	-- Turn ball on only if within square and ROM bit is 1.
	rd_ball_on <= '1' when (sq_ball_on = '1') and (rom_bit = '1') else 
					  '0';
	ball_rgb <= "100"; -- red
	ball_on <= rd_ball_on;
	
	-- Update the ball position 60 times per second.
	ball_x_next <= "0100111011" when scored = '1' else
						ball_x_reg + x_delta_reg when refr_tick = '1' else 
						ball_x_reg;
	ball_y_next <= ball_y_reg + y_delta_reg when refr_tick = '1' else 
						ball_y_reg;
						
	player_scored <= scored;
						
	-- Set the value of the next ball position according to
	-- the boundaries.
	process(x_delta_reg, y_delta_reg, ball_y_t, ball_x_l, ball_x_r, 
			  ball_y_t, ball_y_b, paddle1_on, paddle2_on, rd_ball_on, p2_score_reg, p1_score_reg)
	begin
		x_delta_next <= x_delta_reg;
		y_delta_next <= y_delta_reg;
		p1_score_next <= p1_score_reg;
		p2_score_next <= p2_score_reg;
		scored <= '0';
			
		-- ball reached top, make offset positive
		if ( ball_y_t < MAX_Y_T - 1 ) then
			y_delta_next <= BALL_V_P;
		-- reached bottom, make negative
		elsif (ball_y_b > (MAX_Y_B - 1)) then
			y_delta_next <= BALL_V_N;
		-- Hit left paddle
		elsif(paddle1_on = '1' and rd_ball_on = '1') then
			x_delta_next <= BALL_V_P;
		-- Hit right paddle
		elsif(paddle2_on = '1' and rd_ball_on = '1') then
			x_delta_next <= BALL_V_N;
		-- Player 2 scored
		elsif(ball_x_l < 8) then
			p2_score_next <= p2_score_reg + 1;
			scored <= '1';
			x_delta_next <= BALL_V_P;
		elsif(ball_x_r > (MAX_X - 8)) then
			p1_score_next <= p1_score_reg + 1;
			scored <= '1';
			x_delta_next <= BALL_V_N;
		end if;
	end process;
	
	player1_score <= std_logic_vector(p1_score_next);
	player2_score <= std_logic_vector(p2_score_next);
	
end ball_arch;