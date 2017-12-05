

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- N is the size of the register that holds the counter in bits.
-- M represents the modulo value, i.e., if 10, counter counts to 9 and wraps
entity SlowClockGen is
	generic(
      N: integer := 4;
      M: integer := 10
   );
	port(
      clk_in, reset : in std_logic;
      slow_clock_out : out std_logic
   );
end SlowClockGen;

architecture beh of SlowClockGen is
   signal r_reg: unsigned(N-1 downto 0);
   signal r_next: unsigned(N-1 downto 0);
   begin

-- sequential logic that creates the FF
   process(clk_in, reset)
      begin
         if (reset = '1') then
            r_reg <= (others => '0');
         elsif (clk_in'event and clk_in='1') then
            r_reg <= r_next;
         end if;
   end process;

-- next state logic for the FF, count from 0 to M-1 and wrap
   r_next <= (others => '0') when r_reg=(M-1) else r_reg + 1;

-- generate a 1 clock cycle wide 'tick' when counter reaches max value
   slow_clock_out <= '1' when r_reg=(M-1) else '0';

end beh;


----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SevenSeg_Control is
port(
		clk, reset : in std_logic;
		digit1, digit2 : in std_logic_vector(2 downto 0); -- 0 - 7
		cathodes : out std_logic_vector(7 downto 0);
		anodes : out std_logic_vector(3 downto 0)
	);
end SevenSeg_Control;

architecture Behavioral of SevenSeg_Control is

   type state_type is (idle, digit1_state, digit2_state);
   signal state_reg, state_next : state_type; 
	
   signal led_clk_tick : std_logic;
   signal cathode_reg, cathode_next : std_logic_vector(7 downto 0);
   signal anode_reg, anode_next: std_logic_vector(3 downto 0);
	signal sevenSeg_num_control : std_logic_vector(2 downto 0);
	signal sevenSeg_Cathodes : std_logic_vector(7 downto 0);

begin

-- Connect output signals
    cathodes <= not cathode_reg; -- 0 turns on, 1 turns off
    anodes <= not anode_reg;

   LED_Clk_inst: entity work.SlowClockGen(beh)
      generic map ( N=>15, M=>25000) 
      port map (clk_in => clk, reset => reset, slow_clock_out => led_clk_tick);

	-- Numbers
	with sevenSeg_num_control select
		sevenSeg_Cathodes <=	"00111111" when "000",	-- 0
									"00000110" when "001",	-- 1
									"01011011" when "010",	-- 2
									"01001111" when "011",	-- 3
									"01100110" when "100",	-- 4
									"01101101" when "101",	-- 5
									"01111101" when "110",  -- 6
									"00000111" when "111";	-- 7
		
   process (clk, reset) is 
      begin 
         if (reset = '1') then 
            state_reg <= idle;
            cathode_reg <= (others => '1'); -- '1' is off
            anode_reg <= (others => '1');   -- '1' is off
        elsif (clk'event and clk = '1') then 
            state_reg <= state_next;
            cathode_reg <= cathode_next;
            anode_reg <= anode_next;
        end if;
    end process;

   FSM_proc: process (state_reg, cathode_reg, anode_reg, led_clk_tick, sevenSeg_Cathodes, digit1, digit2) is 
      begin 

-- Default assignment statements
      state_next <= state_reg;
      cathode_next <= cathode_reg;
      anode_next <= anode_reg;
		sevenSeg_num_control <= "000";
        
-- FSM state processing 
      case state_reg is 
         when idle => 
            cathode_next <= X"00";
            anode_next <= X"0";
            if (led_clk_tick = '1') then 
               state_next <= digit1_state;
            end if;

         when digit1_state => 
-- Assert pattern for Player 1 score 
            cathode_next <= sevenSeg_Cathodes;
            anode_next <= "0100";
				sevenSeg_num_control <= digit1;
            if (led_clk_tick = '1') then 
               state_next <= digit2_state;
            end if;

         when digit2_state => 
-- Assert pattern for Player 2 score
            cathode_next <= sevenSeg_Cathodes;
            anode_next <= "0001";
				sevenSeg_num_control <= digit2;
            if (led_clk_tick = '1') then 
               state_next <= digit1_state;
            end if;
                    
         when others => 
            state_next <= idle;
        end case;
    end process;
	 
end Behavioral;
