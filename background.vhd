library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity background is
port(
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		background_on : out std_logic;
		background_rgb : out std_logic_vector(2 downto 0)
	);
end background;

architecture background_arch of background is
	
	-- x, y coordinates (0,0 to (639, 479)
	signal pix_x, pix_y: unsigned(9 downto 0);
	
	-- screen dimensions
	constant MAX_X: integer := 640;
	constant MAX_Y: integer := 480;
	
	-- left wall, left and right boundary of wall (full height)
	constant UPPER_WALL_Y_T: integer := 40;
	constant UPPER_WALL_Y_B: integer := 50;
	
	constant LOWER_WALL_Y_T: integer := 430;
	constant LOWER_WALL_Y_B: integer := 440;
	
	constant CENTER_WALL_X_L: integer := 310;
	constant CENTER_WALL_X_R: integer := 330;
	constant CENTER_WALL_Y_T: integer := 50;
	constant CENTER_WALL_Y_B: integer := 430;
	
	signal upper_wall_on, lower_wall_on, center_wall_on, wall_on : std_logic;
	signal wall_rgb, initials_rgb : std_logic_vector(2 downto 0);
	-- ====================================================
	
	-- My initials EC
	type rom_type is array(0 to 31) of std_logic_vector(31 downto 0);
	constant E_ROM: rom_type:= (
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0",
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0",
		X"000000F0", X"000000F0", X"000000F0", X"000000F0",
		X"000000F0", X"0FFFFFF0", X"0FFFFFF0", X"0FFFFFF0",
		X"0FFFFFF0", X"0FFFFFF0", X"0FFFFFF0", X"000000F0",
		X"000000F0", X"000000F0", X"000000F0", X"000000F0",
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0",
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0"

	);
	constant INITIAL_E_X_L : unsigned(9 downto 0) := "0000000100"; --5;
	constant INITIAL_E_X_R : unsigned(9 downto 0) := "0000100100"; --37;
   
	constant INITIAL_EC_Y_T : unsigned(9 downto 0) := "0000000011"; --4;
	constant INITIAL_EC_Y_B : unsigned(9 downto 0) := "0000100011"; --36;

	constant INITIAL_C_X_L : unsigned(9 downto 0) := "0000100111"; --40;
	constant INITIAL_C_X_R : unsigned(9 downto 0) := "0001000111"; --72;
	
	constant C_ROM: rom_type:= (
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0",
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0",
		X"000000F0", X"000000F0", X"000000F0", X"000000F0",
		X"000000F0", X"000000F0", X"000000F0", X"000000F0",
		X"000000F0", X"000000F0", X"000000F0", X"000000F0",
		X"000000F0", X"000000F0", X"000000F0", X"000000F0",
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0",
		X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0", X"FFFFFFF0"
		
	);

	
	signal rom_addr, rom_col: unsigned(4 downto 0);
	signal rom_data: std_logic_vector(31 downto 0);
	signal rom_bit: std_logic;
	
	-- object output signals -- new signal to indicate if
	-- scan coord is within ball
	signal sq_e_on, sq_c_on, initial_on : std_logic;
	-- ====================================================


begin
	
	pix_x <= unsigned(pixel_x);
	pix_y <= unsigned(pixel_y);
					 
	-- pixel within square E
--	sq_e_on <= '1' when  (INITIAL_E_X_L <= pix_x) and (pix_x <= INITIAL_E_X_R) and
--								(INITIAL_EC_Y_T <= pix_y) and (pix_y <= INITIAL_EC_Y_B) else 
--						  '0';
--	-- pixel within square C
--	sq_c_on <= '1' when 	(INITIAL_C_X_L <= pix_x) and (pix_x <= INITIAL_C_X_R) and
--								(INITIAL_EC_Y_T <= pix_y) and (pix_y <= INITIAL_EC_Y_B) else 
--				  '0';
	
	-- map scan coord to ROM addr/col -- use low order three
	-- bits of pixel and ball positions.
	-- ROM row
	rom_addr <= pix_y(4 downto 0) - INITIAL_EC_Y_T(4 downto 0);
	-- ROM column
	rom_col <= pix_x(4 downto 0) - INITIAL_E_X_L(4 downto 0) when sq_e_on = '1' else
				  pix_x(4 downto 0) - INITIAL_C_X_L(4 downto 0);
	-- Get row data
	rom_data <= E_ROM(to_integer(rom_addr)) when sq_e_on = '1' else
					C_ROM(to_integer(rom_addr));
					
	-- Get column bit
	rom_bit <= rom_data(to_integer(rom_col));
	
	-- Turn ball on only if within square and ROM bit is 1.
	initial_on <= '1' when ((sq_e_on = '1') or (sq_c_on = '1')) and (rom_bit = '1') else
					  '0';
					 
	upper_wall_on <= '1' when (UPPER_WALL_Y_T <= pix_y) and (pix_y <= UPPER_WALL_Y_B) else 
						  '0';
	
	lower_wall_on <= '1' when (LOWER_WALL_Y_T <= pix_y) and (pix_y <= LOWER_WALL_Y_B) else 
						  '0';
				
--	center_wall_on <= '1' when (CENTER_WALL_X_L <= pix_x) and (pix_x <= CENTER_WALL_X_R) and
--										(CENTER_WALL_Y_T <= pix_y) and (pix_y <= CENTER_WALL_Y_B) else 
--						   '0';
						  
	wall_on <= upper_wall_on or lower_wall_on or center_wall_on;
	
	background_on <= wall_on;
	
	wall_rgb <= "010"; -- green
	initials_rgb <= "100"; -- red
	
	background_rgb <= wall_rgb when wall_on = '1' else
							initials_rgb when initial_on = '1' else
							"000";
	
end background_arch;