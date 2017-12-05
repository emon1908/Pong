----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2017 08:21:46 AM
-- Design Name: 
-- Module Name: tb_switch_logic - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_switch_logic is
--  Port ( );
end tb_switch_logic;

architecture Behavioral of tb_switch_logic is
    -- Components
    component switch_logic
        port(
            switches_inputs : in STD_LOGIC_VECTOR (2 downto 0);
            outputs : out STD_LOGIC_VECTOR (2 downto 0)
        );
    end component;
    --Inputs
    signal switches_inputs: std_logic_vector (2 downto 0) := (others => '0');
    --Outputs
    signal outputs: std_logic_vector (2 downto 0);
    
    begin
    uut: switch_logic port map (
        switches_inputs => switches_inputs,
        outputs => outputs
    );
    --Processes
    A_process:process
        begin
        switches_inputs(0) <= '0';
        wait for 100ns;
        switches_inputs(0) <= '1';
        wait for 100ns;
    end process;
    B_process:process
        begin
        switches_inputs(1) <= '0';
        wait for 200ns;
        switches_inputs(1) <= '1';
        wait for 200ns;
    end process;
    C_process:process
        begin
        switches_inputs(2) <= '0';
        wait for 400ns;
        switches_inputs(2) <= '1';
        wait for 400ns;
    end process;
    --Stimulation Process
    stim_proc:process
        begin
        wait;
    end process;
end Behavioral;
