library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ROM is port(
	clk: in std_logic;
	clr: in std_logic;
	address: in std_logic_vector(7 downto 0);
	data_out : out std_logic_vector(23 downto 0)
);
end ROM;

architecture a_ROM of ROM is
	
	constant OP_NOP:  std_logic_vector(5 downto 0):=  "000000";
	constant OP_LOAD: std_logic_vector(5 downto 0):=  "000001";
	constant OP_ADDI: std_logic_vector(5 downto 0):=  "000010";
	constant OP_RGB: std_logic_vector(5 downto 0):=  "000011";
	constant OP_ADEC: std_logic_vector(5 downto 0):=  "000100";
	constant OP_BNZ: std_logic_vector(5 downto 0):=   "000101";
	constant OP_BZ: std_logic_vector(5 downto 0):=    "000110";
	constant OP_BS: std_logic_vector(5 downto 0):=    "000111";
	constant OP_BNS: std_logic_vector(5 downto 0):=   "001000";
	constant OP_BNC: std_logic_vector(5 downto 0):=   "001001";
	constant OP_BC: std_logic_vector(5 downto 0):=    "001010";
	constant OP_BNV: std_logic_vector(5 downto 0):=   "001011";
	constant OP_BV: std_logic_vector(5 downto 0):=    "001100";
	constant OP_HALT: std_logic_vector(5 downto 0):=  "001101";
	constant OP_ADD: std_logic_vector(5 downto 0):=   "001110";
	constant OP_SUB: std_logic_vector(5 downto 0):=   "011111";
	constant OP_MULT: std_logic_vector(5 downto 0):=  "010000";
	constant OP_DIV: std_logic_vector(5 downto 0):=   "010001";
	constant OP_MULTI: std_logic_vector(5 downto 0):= "010010";
	constant OP_DIVI: std_logic_vector(5 downto 0):=  "010011";
	constant OP_COMP1: std_logic_vector(5 downto 0):= "010100";
	constant OP_COMP2: std_logic_vector(5 downto 0):= "010101";
	constant OP_JMP: std_logic_vector(5 downto 0):=   "010110";
	constant OP_LOADI: std_logic_vector(5 downto 0):=  "010111";
	constant OP_CMP: std_logic_vector(5 downto 0):=   "011000";
	constant OP_CMPI: std_logic_vector(5 downto 0):=  "011001";
	constant OP_JR: std_logic_vector(5 downto 0):=    "011010";
	constant OP_JA: std_logic_vector(5 downto 0):=    "011011";

	--Control RPG
	constant RA: std_logic_vector(1 downto 0):= "00";
	constant RB: std_logic_vector(1 downto 0):= "01";
	constant RC: std_logic_vector(1 downto 0):= "10"; 
	constant RD: std_logic_vector(1 downto 0):= "11";

	--TIPO I |OP CODE(6)| REGISTRO DESTINO(2) | DIRECCION DE MEMORIA (16) Y OP A REALIZAR|
	--TIPO R |OP CODE(6)| REGISTRO DESTINO(2) | DIRECCION DE MEMORIA (16)|
	--TIPO J |OP CODE(6)| DIRECCION DE MEMORIA (18)|
	type ROM_Array is array (0 to 255) of std_logic_vector(23 downto 0);
	constant content: ROM_Array := (
		0 => OP_RGB&"0000000000"&x"58",
		1 => OP_LOADI&RA&x"0001",
		2 => OP_LOADI&RB&x"0004",
		3 => OP_JMP&"00"&x"00F8",
		4 => OP_RGB&"0000000000"&x"60",
		5 => OP_LOADI&RA&x"0001",
		6 => OP_LOADI&RB&x"0008",
		7 => OP_JMP&"00"&x"00F8",
		8 => OP_RGB&"0000000000"&x"68",
		9 => OP_LOADI&RA&x"0001",
		10 => OP_LOADI&RB&x"000C",
		11 => OP_JMP&"00"&x"00F8",
		12 => OP_RGB&"0000000000"&x"70",
		13 => OP_LOADI&RA&x"0001",
		14 => OP_LOADI&RB&x"0000",
		15 => OP_JMP&"00"&x"00F8",
		
		248=>OP_ADEC&RA&x"0000",--DEC RA
		249 =>OP_LOADI&RC&x"0008",--LOADI FFFF, RC
		250 =>OP_ADEC&RC&x"0000",--DEC RC
		251 =>OP_NOP&"000000000000000000",--NOP
		252=>OP_BNZ&"10"&x"00FE",--BNZ -2
		253 =>OP_CMPI&RA&x"0001",--CMPI RA,0
		254 =>OP_BS&"10"&x"00FA",--BS -6  T<1
		255 =>OP_JR&RB&x"0000",--JR RB
		others => x"000000"
	);
begin
	process(clk,clr,address)
	begin
		if(clr='1') then	
			data_out<=(others=>'Z');
		elsif(clk'event and clk='1') then
			data_out<=content(conv_integer(address));
		end if;
	end process;
end a_ROM;
					