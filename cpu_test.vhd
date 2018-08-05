--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:24:29 03/25/2018
-- Design Name:   
-- Module Name:   C:/Users/Dylanbrophy/XilinxProjectsXN/Core180325/cpu_test.vhd
-- Project Name:  Core180325
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: CPU
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY cpu_test IS
END cpu_test;
 
ARCHITECTURE behavior OF cpu_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT CPU
    PORT(
         DATA : INOUT  std_logic_vector(7 downto 0);
         clk : IN  std_logic;
         MEM : OUT  std_logic;
         IO : OUT  std_logic;
         RD : OUT  std_logic;
         WR : OUT  std_logic;
         rst : in  std_logic;
         ADR : OUT  std_logic_vector(23 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';

	--BiDirs
   signal DATA : std_logic_vector(7 downto 0);

 	--Outputs
   signal MEM : std_logic;
   signal IO : std_logic;
   signal RD : std_logic;
   signal rst : std_logic;
   signal WR : std_logic;
   signal ADR : std_logic_vector(23 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	type reg_array is array (0 to 14) of std_logic_vector(7 downto 0);
	signal regs: reg_array := (X"F8",X"00",X"00",X"56",X"55",X"FB",X"00",X"00",X"00",X"00",X"6B",X"77",X"77",X"00",X"00");
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: CPU PORT MAP (
          DATA => DATA,
          clk => clk,
          MEM => MEM,
          IO => IO,
          RD => RD,
          WR => WR,
          ADR => ADR,
			 rst => rst
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		if(rd='1' and wr='0' and mem='0')then
			regs(to_integer(unsigned(adr)))<=data;
		end if;
		wait for clk_period/2;
   end process;
	data<=(others=>'Z') when wr='0' or mem='1' else
			regs(to_integer(unsigned(adr)));
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rst<='0';
      wait for 20 ns;	
		rst<='1';

      -- insert stimulus here 

      wait;
   end process;

END;
