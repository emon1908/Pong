library ieee;
use ieee.std_logic_1164.all;

entity pong_top_st is
port(
		clk, reset : in std_logic;
		sys_pause, continue : in std_logic;
		player1_controls : in std_logic_vector(1 downto 0);
		player2_controls : in std_logic_vector(1 downto 0);
		hsync, vsync : out std_logic;
		rgb : out std_logic_vector(2 downto 0);
		anodes : out std_logic_vector(3 downto 0);
		cathodes : out std_logic_vector(7 downto 0)
	);
end pong_top_st;

architecture arch of pong_top_st is

	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal video_on, ball_on, paddle1_on, paddle2_on, background_on : std_logic; 
	signal pixel_tick : std_logic;
	signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
	signal paddle1_rgb, paddle2_rgb, ball_rgb, background_rgb : std_logic_vector(2 downto 0);
	signal player1_score, player2_score : std_logic_vector(2 downto 0);
	signal pause, state_pause : std_logic;
	signal player_scored : std_logic;
	
	type states_type is (spause, splay, sgame_over);
	signal PSR : states_type;

begin
	pause <= state_pause or sys_pause;

	process(clk, reset, player1_score, player2_score) is
	begin
		if(reset = '1') then
			PSR <= spause;
			state_pause <= '1';
		elsif(rising_edge(clk)) then
			case PSR is
				when spause =>
					state_pause <= '1';
					if(continue = '1') then
						PSR <= splay;
					else
						PSR <= spause;
					end if;
				when splay =>
					state_pause <= '0';
					if(player_scored = '1') then
						if(player1_score = "111") then
							PSR <= sgame_over;
						elsif(player2_score = "111") then
							PSR <= sgame_over;
						else
							PSR <= spause;
						end if;
					else
						PSR <= splay;
					end if;
				
				when sgame_over =>
					state_pause <= '1';
					PSR <= sgame_over;
			end case;
		end if;
	end process;
	
	-- instantiate VGA sync
	vga_sync_unit: entity work.vga_sync
	port map(clk => clk, 
				reset => reset,
				video_on => video_on, 
				p_tick => pixel_tick,		
				hsync => hsync, 
				vsync => vsync,
				pixel_x => pixel_x, 
				pixel_y => pixel_y
				);
				
	background_grf_unit: entity work.background(background_arch)
	port map(background_on => background_on,
				pixel_x => pixel_x,
				pixel_y => pixel_y,
				background_rgb => background_rgb
				);

	sevenSegControl_unit: entity work.SevenSeg_Control(Behavioral)
	port map(clk => clk,
				reset => reset,
				digit1 => player1_score,
				digit2 => player2_score,
				cathodes => cathodes,
				anodes => anodes
				);
				
	-- instantiate pixel generation circuit
	ball_grf_st_unit: entity work.ball(ball_arch)
	port map(clk => clk,
				reset => reset,
				pause => pause,
				paddle1_on => paddle1_on,
				player1_score => player1_score,
				player_scored => player_scored,
				paddle2_on => paddle2_on,
				player2_score => player2_score,
				ball_on => ball_on,
				pixel_x => pixel_x,
				pixel_y => pixel_y, 
				ball_rgb => ball_rgb
				);
				
		-- instantiate pixel generation circuit
	paddle1_grf_st_unit: entity work.paddle(paddle_arch)
	port map(clk => clk,
				reset => reset,
				pause => pause,
				btn => player1_controls,
				location => "0000110010", -- 50
				paddle_on => paddle1_on, 
				pixel_x => pixel_x,
				pixel_y => pixel_y, 
				paddle_rgb => paddle1_rgb
				);
	
	-- instantiate pixel generation circuit
	paddle2_grf_st_unit: entity work.paddle_still(paddle_arch_still)
	port map(clk => clk,
				reset => reset,
				pause => pause,
				btn => player2_controls,
				location => "1001011000", -- 600
				paddle_on => paddle2_on, 
				pixel_x => pixel_x,
				pixel_y => pixel_y, 
				paddle_rgb => paddle2_rgb
				);	
				
	process(paddle1_rgb, paddle2_rgb, ball_rgb, background_rgb, 
			  paddle1_on, paddle2_on, ball_on, background_on, video_on) is
	begin
		if(video_on = '1') then
			if(paddle1_on = '1') then
				rgb_next <= paddle1_rgb;
			elsif(paddle2_on = '1') then
				rgb_next <= paddle2_rgb;
			elsif(ball_on = '1') then
				rgb_next <= ball_rgb;
			else
				rgb_next <= background_rgb;
			end if;
		else
			rgb_next <= "000";
		end if;
	end process;
	
	-- rgb buffer, graph_rgb is routed to the ouput through
	-- an output buffer -- loaded when pixel_tick = '1'.
	-- This syncs. rgb output with buffered hsync/vsync sig.
	process (clk)
	begin
		if (clk'event and clk = '1') then
			if (pixel_tick = '1') then
			rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	
	rgb <= rgb_reg;

end arch;