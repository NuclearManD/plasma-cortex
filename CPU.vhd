----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:58:41 03/25/2018 
-- Design Name: 
-- Module Name:    CPU - Behavioral 
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

entity CPU is
    Port (  DATA_in : in  STD_LOGIC_VECTOR (15 downto 0);
				data_out:out  STD_LOGIC_VECTOR (15 downto 0);
           clk : in  STD_LOGIC;
           MEM : out  STD_LOGIC;
           IO : out  STD_LOGIC;
           RD : out  STD_LOGIC;
           WR : out  STD_LOGIC;
			  hold:in std_logic;
           rst : in  STD_LOGIC;
           ADR : out  STD_LOGIC_VECTOR (31 downto 0));
end CPU;

architecture Behavioral of CPU is

	COMPONENT ALU
	PORT(
		a : IN std_logic_vector(31 downto 0);
		b : IN std_logic_vector(31 downto 0);
		op : IN std_logic_vector(3 downto 0);          
		y : OUT std_logic_vector(31 downto 0);
		calc : in STD_LOGIC;
		f : out STD_LoGIc_VectoR(3 downto 0);
			  clk : in std_logic); -- flags: carry, !carry, zero, !zero
	END COMPONENT;
	signal opcode : std_logic_vector(7 downto 0);
	signal op_ft : std_logic_vector(7 downto 0);
	signal state  : integer range 0 to 11 := 0;
	type reg_array is array (0 to 7) of std_logic_vector(31 downto 0);
	signal regs: reg_array := (X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000");
	signal a : std_logic_vector(31 downto 0);
	signal ax: std_logic_vector(31 downto 0);
	signal b : std_logic_vector(31 downto 0);
	signal y : std_logic_vector(31 downto 0);
	signal op: std_logic_vector(3 downto 0);
	
	
	signal pc_next : std_logic_vector(31 downto 0);
	
	signal count : integer range 0 to 15;
	signal tmp : std_logic_vector(31 downto 0);
	
	signal t_adr : std_logic_vector(31 downto 0);
	signal fetch_adr : std_logic_vector(31 downto 0);
	
	signal calc   : std_logic;
	signal flags  : std_logic_vector(3 downto 0);
	
	signal pc_add : integer range 0 to 6;
	
	signal movrd : std_logic; -- mov r1, *
	signal movrr : std_logic; -- mov r1, r2
	signal iodx  : std_logic; -- in/out dx, ax
	signal movfr : std_logic; -- mov r1, [r2]
	signal movto : std_logic; -- mov [r2], r1
	signal djnz  : std_logic; -- djnz *
	signal math  : std_logic; -- (math)
	
	begin
	
		Inst_ALU: ALU PORT MAP(
			a => a,
			b => b,
			y => y,
			op => op,
			calc=> calc,
			f => flags,
			clk=>clk
		);
		ADR <= fetch_adr when state=0 or state=1 or state=6 or state=10 or state=11 else
				 std_logic_vector(
				 unsigned(
				 t_adr)+
				 to_unsigned(
				 count,24))			when state=4 or state=5 else
				 t_adr;
		MEM<= '1' when state=7 or state=8 or state=9 else
				'0';
		IO <= '0' when state=8 or state=9 else
				'1';
		
		process(clk,rst)
		begin
			if(rst='0')then
				state<=10;
				count<=0;
				DATA<=(others=>'Z');
				rd<='0';
				wr<='1';
			elsif(hold='0')then
			-- wait
			elsif(rising_edge(clk))then
				if(state=0)then
					rd    <= '0';
					wr    <= '1';
					state <= 1;
					calc  <= '0';
					count <= 0;
					opcode<= DATA_in;
					movrd <= '0';-- mov r1, *
					movrr <= '0';-- mov r1, r2
					iodx  <= '0';-- in/out dx, ax
					movto <= '0';-- mov [r2], r1
					movfr <= '0';-- mov r1, [r2]
					djnz  <= '0';-- djnz *
					math  <= '0';-- (math)
					
					if(data_in(7 downto 3)="11111")then
						movrd <= '1';-- mov r1, *
					elsif(data_in(7)='0' and data_in(3)='0')then
						movrr <= '1';-- mov r1, r2
					elsif(data_in(7 downto 1)="0110101")then
						iodx  <= '1';-- in/out dx, ax
					elsif(data_in(3)='1' and (data_in(7 downto 4)="1011" or data_in(7 downto 5)="110"))then
						movto <= '1';-- mov [r2], r1
					elsif(data_in(3)='1' and (data_in(7 downto 4)="0011" or data_in(7 downto 5)="010"))then
						movfr <= '1';-- mov r1, [r2]
					elsif(data_in(7 downto 0)=X"6C")then
						djnz  <= '1';-- djnz *
					elsif(data_in(7)='1' and data_in(3)='0')then
						math  <= '1';-- (math)
					end if;
				elsif(state=1)then
					if(movrr='1')then			-- mov r1, r2
						tmp<=regs(to_integer(unsigned(opcode(6 downto 4))));
						state<=2; -- Q
						if(opcode(6 downto 4)/="111")then
							pc_add<=1;
						else
							pc_add<=0;
						end if;
					elsif(movrd='1')then					-- mov r1, *
						count<=0;
						state<=4;
						pc_add<=5;
						t_adr<=std_logic_vector(unsigned(regs(7)(23 downto 0))+1);
					elsif(movto='1')then		-- mov [r2], r1
						count<=0;
						t_adr<=regs(to_integer(unsigned(opcode(6 downto 4))));
						state<=5;
						tmp<=regs(to_integer(unsigned(opcode(2 downto 0))));
						pc_add<=1;
						rd    <= '1';
						wr    <= '0';
					elsif(movfr='1')then		-- mov r1, [r2]
						count<=0;
						t_adr<=regs(to_integer(unsigned(opcode(6 downto 4))));
						state<=4;
						pc_add<=1;
					elsif(djnz='1')then									-- djnz *
						a<=regs(2);
						b<=X"00000001";
						op<="0001"; -- subtract
						calc<='1';
						state<=5;
						pc_add<=5;
					elsif(iodx='1')then				-- in/out dx, ax(7 downto 0)
						t_adr<=regs(3);
						if(opcode(0)='1')then
							state<=7;
						else
							state<=8;
						end if;
						pc_add<=1;
					elsif(math='1')then				-- (math)
						state<=5;
						op<=opcode(6)&opcode(2 downto 0);
						a<=ax;
						b<=regs(to_integer(unsigned(opcode(6 downto 4))));
						pc_add<=1;
					else
						regs(7)<=X"00000200";			 					-- invalid opcode
						pc_add<=0;
						state<=11;
					end if;
				elsif(state=2)then
					if(movrr='1')then					-- mov r1, r2
						regs(to_integer(unsigned(opcode(2 downto 0))))<=tmp;
						state<=11;
					elsif(math='1')then				-- (math)
						if(opcode(6)='0')then
							a<=ax;
						else
							a<=regs(to_integer(unsigned(opcode(6 downto 4))));
						end if;
						b<=regs(to_integer(unsigned(opcode(6 downto 4))));
						op<=opcode(6)&opcode(2 downto 0);
						state<=3;
					elsif(movrd='1')then   			-- mov r1, *
						regs(to_integer(unsigned(opcode(2 downto 0))))<=tmp;
						state<=11;
					elsif(movto='1')then 			-- mov [r2], r1
						state<=11;
					elsif(movat='1')then 			-- mov r1, [r2] / mov [r2], r1
						t_adr<=std_logic_vector(unsigned(regs(to_integer(unsigned(opcode(6 downto 4)))))+to_unsigned(count+1,24));
						count<=count+1;
						if(opcode(7)='0')then
							tmp<=tmp(23 downto 0)&DATA;
							if(count=3)then
								state<=11;
								regs(to_integer(unsigned(opcode(2 downto 0))))<=tmp(16 downto 0)&DATA_in;
							end if;
						else
							tmp(31 downto 8)<=tmp(23 downto 0);
							DATA_out<=tmp(31 downto 16);
							if(count=3)then
								state<=11;
							end if;
						end if;
					elsif(djnz='1')then				-- djnz *
						if(flags(1)='0')then
							movrd<='1';
							djnz<='0';
							count<=0;
							state<=4; -- read 4 bytes (and then execute code for opcode 0xFF)
							t_adr<=regs(7);
						else
							state<=11;
						end if;
						regs(2)<=y;
					else
						state<=1;
					end if;
				elsif(state=3)then
					state<=11;
					if(math='1')then
						if(opcode(6)='0')then
							regs(0)<=y;
						else
							regs(to_integer(unsigned(opcode(6 downto 4))))<=y;
						end if;
					elsif(opcode="01101000")then							-- in dx, ax(7 downto 0)
						regs(0)(15 downto 0)<=tmp(15 downto 0);
					end if;
				elsif(state=4)then -- read 32 bits
					tmp<=tmp(15 downto 0)&DATA_in;
					if(count=1)then
						state<=2;
						count<=0;
					else
						count<=count+1;
					end if;
				elsif(state=5)then -- write 32 bits
					tmp<=X"00"&tmp(31 downto 16);
					DATA_out<=tmp(15 downto 0);
					if(count=1)then
						state<=2;
						count<=0;
					else
						count<=count+1;
					end if;
				elsif(state=6)then -- ALU cycles
					if(count=1)then
						state<=2;
						count<=0;
					else
						count<=count+1;
					end if;
				elsif(state=7)then
					state<=9;
					DATA_out<=ax(15 downto 0);
				elsif(state=8)then
					state<=3;
					regs(0)(15 downto 0)<=daTa_in;
				elsif(state=9)then
					state<=3;
					data<="ZZZZZZZZ";
				elsif(state=10)then
					pc_add<=0;
					regs<=(X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000");
					state<=11;
				elsif(state=11)then
					regs(7)<=pc_next;
					state<=0;
					rd<='0';
					wr<='1';
				end if;
			end if;
		end process;
		ax<=regs(0);
		pc_next<=std_logic_vector(unsigned(regs(7))+pc_add);
end Behavioral;

