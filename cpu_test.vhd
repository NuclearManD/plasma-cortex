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
         DATA_in : INOUT  std_logic_vector(15 downto 0);
         DATA_out : INOUT  std_logic_vector(15 downto 0);
         clk : IN  std_logic;
         MEM : OUT  std_logic;
         IO : OUT  std_logic;
         RD : OUT  std_logic;
         WR : OUT  std_logic;
         n_ub : OUT  std_logic;
         n_lb : OUT  std_logic;
         rst : in  std_logic;
         hold : in  std_logic;
         ADR : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';

	--BiDirs
   signal DATA_in : std_logic_vector(15 downto 0);
   signal DATA_out : std_logic_vector(15 downto 0);

 	--Outputs
   signal MEM : std_logic;
   signal IO : std_logic;
   signal RD : std_logic;
   signal n_ub : std_logic;
   signal n_lb : std_logic;
   signal rst : std_logic;
   signal WR : std_logic;
   signal ADR : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	type reg_array is array (0 to 15) of std_logic_vector(7 downto 0);
	-- stack mov test (mov r1, [pc-4])
	-- signal regs: reg_array := (X"FE",X"00",X"00",X"00",X"0F",X"C4",X"88",X"FF",X"FC",X"09",X"FF",X"FC",X"77",X"77",X"00",X"00");
	-- call * test
	-- signal regs: reg_array := (X"FE",X"00",X"00",X"00",X"0E",X"7C",X"00",X"00",X"00",X"05",X"77",X"77",X"77",X"00",X"00",X"00");
	-- push/pop test
	signal regs: reg_array := (X"FE",X"00",X"00",X"00",X"0D",X"A8",X"2F",X"00",X"00",X"05",X"77",X"77",X"77",X"00",X"00",X"00");
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: CPU PORT MAP (
          DATA_in => DATA_in,
			 data_out=> data_out,
          clk => clk,
          MEM => MEM,
          IO => IO,
          RD => RD,
          WR => WR,
			 n_ub=>n_ub,
			 n_lb=>n_lb,
          ADR => ADR,
			 rst => rst,
			 hold =>'1'
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		if(rd='1' and wr='0' and mem='0')then
			if(n_ub='0')then
				regs(to_integer(unsigned(adr(31 downto 1)&'1')))<=data_out(15 downto 8);
			end if;
			if(n_lb='0')then
				regs(to_integer(unsigned(adr(31 downto 1)&'0'))+1)<=data_out(7 downto 0);
			end if;
		end if;
		wait for clk_period/2;
   end process;
	data_in<=regs(to_integer(unsigned(adr(31 downto 1)&'1')))&regs(to_integer(unsigned(adr(31 downto 1)&'0')));
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
