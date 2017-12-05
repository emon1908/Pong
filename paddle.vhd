library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity paddle is
port(
		clk, reset : in std_logic;
		btn : in std_logic_vector(1 downto 0);
		pause : in std_logic;
		location : in std_logic_vector(9 downto 0);
		paddle_on : out std_logic;
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		paddle_rgb : out std_logic_vector(2 downto 0)
	);
end paddle;

architecture paddle_arch of paddle is

	-- Signal used to control how
	-- often pushbuttons are checked for paddle movement.
	signal refr_tick: std_logic;
	
	-- x, y coordinates (0,0 to (639, 479)
	signal pix_x, pix_y: unsigned(9 downto 0);
	
	-- screen dimensions
	constant MAX_X: integer := 640;
	constant MAX_Y_T: integer := 50;
	constant MAX_Y_B: integer := 430;
	
	-- paddle left, right, top, bottom and height left &
	-- right are constant. top & bottom are signals to
	-- allow movement. bar_y_t driven by reg below.
	signal bar_x_l: unsigned(9 downto 0);
	signal bar_x_r: unsigned(9 downto 0);
	signal bar_y_t, bar_y_b: unsigned(9 downto 0);
	constant BAR_Y_SIZE: integer := 100;
	
	-- reg to track top boundary (x position is fixed)
	signal bar_y_reg, bar_y_next: unsigned(9 downto 0):= "0011110000";
	
	-- bar moving velocity when a button is pressed
	-- the amount the bar is moved.
	constant BAR_V: integer:= 4;

begin

	process (clk, reset)
	begin
		if (reset = '1') then
			bar_y_reg <= "0011110000";
		elsif (clk'event and clk = '1') then
			bar_y_reg <= bar_y_next;
		end if;
	end process;

	bar_x_l <= unsigned(location);
	bar_x_r <= unsigned(location) + 3;
	
	pix_x <= unsigned(pixel_x);
	pix_y <= unsigned(pixel_y);
	
	-- refr_tick: 1-clock tick asserted at start of v_sync,
	-- e.g., when the screen is refreshed -- speed is 60 Hz
	refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) and (pause = '0') else 
					 '0';
					 
	-- pixel within paddle
	bar_y_t <= bar_y_reg;
	bar_y_b <= bar_y_t + BAR_Y_SIZE - 1;
	
	paddle_on <= '1' when (bar_x_l <= pix_x) and (pix_x <= bar_x_r) and 
							 (bar_y_t <= pix_y) and (pix_y <= bar_y_b) else 
					 '0';
					 
	paddle_rgb <= "010";
	
	-- Process bar movement requests
	process( bar_y_reg, bar_y_b, bar_y_t, refr_tick, btn)
	begin
		bar_y_next <= bar_y_reg; -- no move
		
		if ( refr_tick = '1' ) then
			-- if btn 0 pressed and paddle not at bottom yet
			if ( btn(0) = '1' and bar_y_b < (MAX_Y_B - 1 - BAR_V)) then
				bar_y_next <= bar_y_reg + BAR_V;
			-- if btn 1 pressed and bar not at top yet
			elsif ( btn(1) = '1' and (bar_y_t - 50) > BAR_V) then
				bar_y_next <= bar_y_reg - BAR_V;
			end if;
		end if;
	end process;
	
	
	
end paddle_arch;