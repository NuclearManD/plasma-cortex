----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:39:01 04/16/2018 
-- Design Name: 
-- Module Name:    Fetch - Behavioral 
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

entity Fetch is
    Port ( PC : in  STD_LOGIC_VECTOR (23 downto 0);
	 PC_next : in  STD_LOGIC_VECTOR (23 downto 0);
           state : in integer range 0 to 11;
           adr : out  STD_LOGIC_VECTOR (23 downto 0);
           data : in  STD_LOGIC_VECTOR (7 downto 0);
			  op : out std_logic_vector(7 downto 0);
			  
			  movrd : out std_logic; -- mov r1, *
			  movrr : out std_logic; -- mov r1, r2
			  iodx  : out std_logic; -- in/out dx, ax
			  movat : out std_logic; -- mov r1, [r2] / mov [r2], r1
			  djnz  : out std_logic; -- djnz *
			  math  : out std_logic; -- (math)
			  
           clk : in  STD_LOGIC
			  );
end Fetch;

architecture Behavioral of Fetch is
	signal next_op : std_logic_vector(7 downto 0);
	signal loaded : std_logic := '0';
begin
	adr<=pc when state=11 or state=10 else
		  pc_next;
	process(clk)
	begin
		if(rising_edge(clk))then
			if(state=11)then
				op<=next_op;
				loaded<='0';
				movrr<='0';
				movrd<='0';
				movat<='0';
				djnz<='0';
				iodx<='0';
				math<='0';
				if(next_op(3)='0' and next_op(7)='0')then			-- mov r1, r2
					movrr<='1';
				elsif(next_op(7 downto 3)="11111")then					-- mov r1, *
					movrd<='1';
				elsif(next_op(6 downto 3)="0111" or 
				(next_op(6 downto 5)="10" and next_op(3)='1'))then		-- mov r1, [r2] / mov [r2], r1
					movat<='1';
				elsif(next_op=X"6C")then									-- djnz *
					djnz<='1';
				elsif(next_op(7 downto 1)="0110101")then				-- in/out dx, ax(7 downto 0)
					iodx<='1';
				elsif(next_op(3)='0' and DATA(7)='1')then				-- (math)
					math<='1';
				end if;
			elsif(state=2 or state=3 or state=6 or state=10)then
				if(loaded='0')then
					next_op<=data;
				end if;
				loaded<='1';
			end if;
		end if;
	end process;

end Behavioral;

