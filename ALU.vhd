----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:44:18 03/25/2018 
-- Design Name: 
-- Module Name:    ALU - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( a : in  STD_LOGIC_VECTOR (31 downto 0);
           b : in  STD_LOGIC_VECTOR (31 downto 0);
           y : out  STD_LOGIC_VECTOR (31 downto 0);
           op : in  STD_LOGIC_VECTOR (3 downto 0);
			  calc : in STD_LOGIC;
			  f : out STD_LoGIc_VectoR(3 downto 0);
			  clk : in std_logic); -- flags: carry, !carry, zero, !zero
end ALU;

architecture Behavioral of ALU is
	signal ai : signed(32 downto 0);
	signal bi : signed(32 downto 0);
	signal yi : signed(32 downto 0);
	signal t1 : signed(31 downto 0);
	signal t2 : signed(31 downto 0);
	signal t3 : signed(31 downto 0);
	signal mul: signed(31 downto 0);
	signal bignegative : std_logic_vector(31 downto 0):=X"80000000";
	begin
		yi<=ai+bi 					when op="0000" else
			 ai-bi 					when op="0001" else
			 '0'&mul					when op="0010" else
			 ai xor bi 				when op="0101" else
			 ai and bi 				when op="0110" else
			 shift_left(bi, 1) 	when op="1000" else
			 shift_right(bi, 1) 	when op="1001" else
			 shift_right(bi, 1)
				or(bi and 
				signed(
				bignegative)) 		when op="1010" else
			 abs(bi) 				when op="1011" else
			 not bi  				when op="1100" else
			 bi+4 					when op="1110" else
			 bi-4 					when op="1111" else
			 to_signed(-1,33);
		process(clk)
		begin
			if(rising_edge(clk))then
				t1<=ai(15 downto 0)*bi(15 downto 0);
				t2<=shift_left(ai(31 downto 16)*bi(15 downto 0),16);
				t3<=shift_left(bi(31 downto 16)*ai(15 downto 0),16);
				mul<=t1+t2+t3;
			end if;
		end process;
		ai<=signed("0"&a);
		bi<=signed("0"&b);
		y<=std_logic_vector(yi(31 downto 0));
		process(calc) 
		begin
			if(rising_edge(calc))then
				if(yi(32)='1')then
					f(0)<='1';
					f(1)<='0';
				else
					f(1)<='1';
					f(0)<='0';
				end if;
				if(yi(31 downto 0)=X"00000000")then
					f(2)<='1';
					f(3)<='0';
				else
					f(3)<='1';
					f(2)<='0';
				end if;
			end if;
		end process;
end Behavioral;

