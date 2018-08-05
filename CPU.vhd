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
	
	signal pcp1 : std_logic_vector(31 downto 0);
	signal pcp5 : std_logic_vector(31 downto 0);
	
	signal spm3 : std_logic_vector(31 downto 0);
	signal spp4 : std_logic_vector(31 downto 0);
	signal spm4 : std_logic_vector(31 downto 0);
	signal spp1 : std_logic_vector(31 downto 0);
	
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
	signal adsp1 : std_logic; -- add sp, *
	signal adsp2 : std_logic; -- add sp, * (phase 2)
	signal call1 : std_logic; -- call *
	signal call2 : std_logic; -- call * (phase 2)
	
	signal inst_cnt : integer:=0;
	
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
		ADR <= regs(7) when state=0 or state=1 or state=6 or state=10 or state=11 else
				 std_logic_vector(
				 unsigned(
				 t_adr)+
				 to_unsigned(
				 count,32))			when state=4 or state=5 else
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
				rd<='0';
				wr<='1';
				inst_cnt<=0;
			elsif(hold='0')then
			-- wait
			elsif(rising_edge(clk))then
				rd<='0';
				wr<='1';
				if(state=0)then
					rd    <= '0';
					wr    <= '1';
					state <= 1;
					calc  <= '0';
					count <= 0;
					opcode<= DATA_in(15 downto 8);
					movrd <= '0'; -- mov r1, *
					movrr <= '0'; -- mov r1, r2
					iodx  <= '0'; -- in/out dx, ax
					movto <= '0'; -- mov [r2], r1
					movfr <= '0'; -- mov r1, [r2]
					djnz  <= '0'; -- djnz *
					math  <= '0'; -- (math)
					adsp1 <= '0'; -- add sp, *
					adsp2 <= '0'; -- add sp, * (phase 2)
					call1 <= '0'; -- add sp, *
					call2 <= '0'; -- add sp, * (phase 2)
					inst_cnt<=inst_cnt+1;
					if(data_in(15 downto 11)="11111")then
						movrd <= '1';-- mov r1, *
						pc_add<=5;
					elsif(data_in(15)='0' and data_in(11)='0')then
						--movrr <= '1';-- mov r1, r2
						state<=11;
						regs(to_integer(unsigned(data_in(10 downto 8))))<=regs(to_integer(unsigned(data_in(14 downto 12))));
						if(data_in(14 downto 12)/="111")then
							pc_add<=1;
						else
							pc_add<=0;
						end if;
					elsif(data_in(15 downto 9)="0110101")then
						iodx  <= '1';-- in/out dx, ax
						pc_add<=1;
					elsif(data_in(11)='1' and (data_in(15 downto 12)="1011" or data_in(15 downto 13)="110"))then
						movto <= '1';-- mov [r2], r1
						pc_add<=1;
					elsif(data_in(11)='1' and (data_in(15 downto 12)="0011" or data_in(15 downto 13)="010"))then
						movfr <= '1';-- mov r1, [r2]
						pc_add<=1;
					elsif(data_in(15 downto 0)=X"6C")then
						pc_add<=5;
						djnz  <= '1';-- djnz *
					elsif(data_in(15)='1' and data_in(11)='0')then
						math  <= '1';-- (math)
						pc_add<=1;
					elsif(data_in(15 downto 8)=X"7D")then
						adsp1<='1';
						t_adr<=pcp1;
						pc_add<=5;
						state<=4;
					elsif(data_in(15 downto 8)=X"7C")then
						call1<='1';
						t_adr<=spm3;
						state<=5;
						tmp<=pcp5;
						pc_add<=0;
					else
					end if;
				elsif(state=1)then
					--if(movrr='1')then			-- mov r1, r2
					--	tmp<=
					--	state<=2; -- Q
					--	if(opcode(6 downto 4)/="111")then
					--		pc_add<=1;
					--	else
					--		pc_add<=0;
					--	end if;
					if(movrd='1')then					-- mov r1, *
						state<=4;
						t_adr<=pcp1;
					elsif(movto='1')then		-- mov [r2], r1
						t_adr<=regs(to_integer(unsigned(opcode(6 downto 4))));
						state<=5;
						tmp<=regs(to_integer(unsigned(opcode(2 downto 0))));
					elsif(movfr='1')then		-- mov r1, [r2]
						t_adr<=regs(to_integer(unsigned(opcode(6 downto 4))));
						state<=4;
					elsif(djnz='1')then									-- djnz *
						a<=regs(2);
						b<=X"00000001";
						op<="0001"; -- subtract
						calc<='1';
						state<=6;
					elsif(iodx='1')then				-- in/out dx, ax(7 downto 0)
						t_adr<=regs(3);
						if(opcode(0)='1')then
							state<=7;
						else
							state<=8;
						end if;
					elsif(math='1')then				-- (math)
						state<=6;
						op<=opcode(6)&opcode(2 downto 0);
						a<=ax;
						b<=regs(to_integer(unsigned(opcode(6 downto 4))));
					else
						regs(7)<=X"00000200";			 					-- invalid opcode
						state<=11;
					end if;
				elsif(state=2)then
					--if(movrr='1')then					-- mov r1, r2
					--	regs(to_integer(unsigned(opcode(2 downto 0))))<=tmp;
					--	state<=11;
					if(math='1')then				-- (math)
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
					elsif(movfr='1')then 			-- mov r1, [r2]
						regs(to_integer(unsigned(opcode(2 downto 0))))<=tmp;
						state<=11;
					elsif(djnz='1')then				-- djnz *
						if(flags(1)='0')then
							movrd<='1';
							djnz<='0';
							count<=0;
							state<=4;-- read 4 bytes (and then execute code for opcode 0xFF)
							t_adr<=regs(7);
						else
							state<=11;
						end if;
						regs(2)<=y;
					elsif(adsp1='1')then
						adsp1<='0';
						adsp2<='1';
						a<=tmp;
						b<=regs(6);
						op<="0000";
						state<=6;
					elsif(adsp2='1')then
						regs(6)<=y;
						state<=11;
					elsif(call1='1')then
						regs(6)<=spm4;
						t_adr<=pcp1;
						call1<='0';
						call2<='1';
						state<=4;
					elsif(call2='1')then
						state<=11;
						regs(7)<=tmp;
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
					elsif(opcode="01101000")then		-- in dx, ax(7 downto 0)
						regs(0)(15 downto 0)<=tmp(15 downto 0);
					end if;
				elsif(state=4)then -- read 32 bits
					tmp<=tmp(15 downto 0)&DATA_in;
					if(count=2)then
						state<=2;
						count<=0;
					else
						count<=count+2;
					end if;
				elsif(state=5)then -- write 32 bits
					rd <= '1';
					wr <= '0';
					tmp<=X"0000"&tmp(31 downto 16);
					DATA_out<=tmp(15 downto 0);
					if(count=2)then
						state<=2;
						count<=0;
					else
						count<=count+2;
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
				elsif(state=10)then
					pc_add<=0;
					regs<=(X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00000000",X"00FFFFFF",X"00000000");
					state<=11;
				elsif(state=11)then
					regs(7)<=pc_next;
					state<=0;
					pcp1<=std_logic_vector(unsigned(pc_next)+1);
					pcp5<=std_logic_vector(unsigned(pc_next)+5);
					spm3<=std_logic_vector(unsigned(regs(6))-3);
					spp4<=std_logic_vector(unsigned(regs(6))+4);
					spm4<=std_logic_vector(unsigned(regs(6))-4);
					spp1<=std_logic_vector(unsigned(regs(6))+1);
				end if;
			end if;
		end process;
		ax<=regs(0);
		pc_next<=std_logic_vector(unsigned(regs(7))+pc_add);
end Behavioral;

