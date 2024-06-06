library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ROM is port(
	clk: in std_logic;
	clr: in std_logic;
	enable: in std_logic;
	read_m : in std_logic; 
	address: in std_logic_vector(7 downto 0);
	data_out : out std_logic_vector(23 downto 0)
);
end ROM;

architecture a_ROM of ROM is
	
	constant OP_NOP:  std_logic_vector(5 downto 0):=  "000000";
	constant OP_LOAD: std_logic_vector(5 downto 0):=  "000001";
	constant OP_ADDI: std_logic_vector(5 downto 0):=  "000010";
	constant OP_DPLY: std_logic_vector(5 downto 0):=  "000011";
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
		--Ecuacion a) 17X + 25Y - W/4
		0 => OP_LOAD&RA&x"00F8",--LOAD X, RA
		1 =>OP_MULTI&RA&x"0011",--MULTI RA,17 
		2 => OP_LOAD&RB&x"00F9",--LOAD Y, RB
		3 =>OP_MULTI&RB&x"0019",--MULTI RB,25 
		4 => OP_LOAD&RC&x"00F7",--LOAD W,RC
		5 => OP_DIVI&RC&x"0004",--DIVI RC,4 
		6 => OP_ADD&RA&RB&RA&x"000",--ADD RA,RB,RA 
		7 => OP_SUB&RA&RC&RA&x"000",--SUB RA,RC,RA 
		8 => OP_DPLY&RA&x"0000",--DPLY RA
		--ASIGNAR TIEMPO T 
		9 =>OP_CMPI&RA&x"0064", --CMPI RA,100
		10=>OP_BNS&"00"&x"0034", --BNS T=2  RA>=100
		11=>OP_CMPI&RA&x"003C", --CMPI RA,60
		12=>OP_BNS&"00"&x"003F",--BS T=3  RA>=60
		13=>OP_CMPI&RA&x"0019", --CMPI RA,25
		14=>OP_JA&"00"&x"004A", --JA T=4 RA>25
		15=>OP_CMPI&RA&x"0000", --CMPI RA,0
		16=>OP_BNS&"00"&x"0029", --BNS T=1 RA>=0
		17=>OP_JMP&"00"&x"0055",-- JMP T=5 RA<0
		--T=RA
		18 => OP_ADEC&RA&"000000000000"&"0011",--DEC RA
		--SECUENCIA PARA 1 SEGUNDO
		19 =>OP_LOADI&RC&x"FFFF",--LOADI FFFF, RC
		20 =>OP_ADEC&RC&"000000000000"&"0011",--DEC RC
		21 =>OP_NOP&"000000000000000000",--NOP
		22 =>OP_NOP&"000000000000000000",--NOP
		23 =>OP_NOP&"000000000000000000",--NOP
		24 =>OP_NOP&"000000000000000000",--NOP
		25 =>OP_NOP&"000000000000000000",--NOP
		26 =>OP_NOP&"000000000000000000",--NOP
		27 =>OP_NOP&"000000000000000000",--NOP
		28 =>OP_NOP&"000000000000000000",--NOP
		29 =>OP_NOP&"000000000000000000",--NOP
		30 =>OP_NOP&"000000000000000000",--NOP
		31 =>OP_NOP&"000000000000000000",--NOP
		32 =>OP_NOP&"000000000000000000",--NOP
		33 =>OP_NOP&"000000000000000000",--NOP
		34 =>OP_NOP&"000000000000000000",--NOP
		35 =>OP_NOP&"000000000000000000",--NOP
		36 =>OP_NOP&"000000000000000000",--NOP
		37 =>OP_BNZ&"10"&x"00EF",--BNZ -17  RC != 0
		--T=RA=0?
		38 =>OP_CMPI&RA&x"0000",--CMPI RA,0
		39 =>OP_BNZ&"10"&x"00EB",--BNZ -21  T !=0
		--SALTAR AL VALOR DE RB
		40 =>OP_JR&RB&x"0000",--JR RB
		
		-- T= 1
		--10 segundos de espera
		41 => OP_LOAD&RA&x"00F2",--LOADI T segundos,RA
		42 => OP_LOADI&RB&x"002D",-- LOADI 45 punto de retorno,RB
		43 => OP_LOADI&RD&x"0000",-- LOADI 0,RD
		44 => OP_JMP&"00"&x"0012",-- JMP 18
		-- T= 1
		45 => OP_LOADI&RA&x"0001",--LOADI 1,RA Segundos de espera
		46 => OP_DPLY&RD&x"0000", --DPLY RD
		47 => OP_ADDI&RD&x"0001", --ADDI RD,1
		48 => OP_CMPI&RD&x"001E", --CMPI RD,30
		49 => OP_BNZ&"10"&x"00FB",--BNZ -5
		50 => OP_DPLY&RD&x"0000", --DPLY RD
		51 => OP_HALT&"000000000000000000",
		-- T= 2
		--10 segundos de espera
		52 => OP_LOAD&RA&x"00F2",--LOADI T segundos,RA
		53 => OP_LOADI&RB&x"0038",-- LOADI 56 punto de retorno,RB 
		54 => OP_LOADI&RD&x"0000",-- LOADI 0,RD
		55 => OP_JMP&"00"&x"0012",-- JMP 18
		-- T= 2
		56 => OP_LOADI&RA&x"0002",--LOADI 2,RA Segundos de espera
		57 => OP_DPLY&RD&x"0000", --DPLY RD
		58 => OP_ADDI&RD&x"0001", --ADDI RD,1
		59 => OP_CMPI&RD&x"001E", --CMPI RD,30
		60 => OP_BNZ&"10"&x"00FB",--BNZ -5
		61 => OP_DPLY&RD&x"0000", --DPLY RD
		62 => OP_HALT&"000000000000000000",
		-- T= 3
		--10 segundos de espera
		63 => OP_LOAD&RA&x"00F2",--LOADI T segundos,RA
		64 => OP_LOADI&RB&x"0043",-- LOADI 67 punto de retorno,RB 
		65 => OP_LOADI&RD&x"0000",-- LOADI 0,RD
		66 => OP_JMP&"00"&x"0012",-- JMP 18
		-- T= 3
		67 => OP_LOADI&RA&x"0003",--LOADI 3,RA Segundos de espera
		68 => OP_DPLY&RD&x"0000", --DPLY RD
		69 => OP_ADDI&RD&x"0001", --ADDI RD,1
		70 => OP_CMPI&RD&x"001E", --CMPI RD,30
		71 => OP_BNZ&"10"&x"00FB",--BNZ -5
		72 => OP_DPLY&RD&x"0000", --DPLY RD
		73 => OP_HALT&"000000000000000000",
		-- T= 4
		--10 segundos de espera
		74 => OP_LOAD&RA&x"00F2",--LOADI T segundos,RA
		75 => OP_LOADI&RB&x"004E",-- LOADI 78 punto de retorno,RB
		76 => OP_LOADI&RD&x"0000",-- LOADI 0,RD		
		77 => OP_JMP&"00"&x"0012",-- JMP 18
		-- T= 4
		78 => OP_LOADI&RA&x"0004",--LOADI 1,RA Segundos de espera
		79 => OP_DPLY&RD&x"0000", --DPLY RD
		80 => OP_ADDI&RD&x"0001", --ADDI RD,1
		81 => OP_CMPI&RD&x"001E", --CMPI RD,30
		82 => OP_BNZ&"10"&x"00FB",--BNZ -5
		83 => OP_DPLY&RD&x"0000", --DPLY RD
		84 => OP_HALT&"000000000000000000",
		-- T= 5
		--10 segundos de espera
		85 => OP_LOAD&RA&x"00F2",--LOADI T segundos,RA
		86 => OP_LOADI&RB&x"0059",-- LOADI 89 punto de retorno,RB
		87 => OP_LOADI&RD&x"0000",-- LOADI 0,RD		
		88 => OP_JMP&"00"&x"0012",-- JMP 18
		-- T= 5
		89 => OP_LOADI&RA&x"0005",--LOADI 1,RA Segundos de espera
		90 => OP_DPLY&RD&x"0000", --DPLY RD
		91 => OP_ADDI&RD&x"0001", --ADDI RD,1
		92 => OP_CMPI&RD&x"001E", --CMPI RD,30
		93 => OP_BNZ&"10"&x"00FB",--BNZ -5
		94 => OP_DPLY&RD&x"0000", --DPLY RD
		95 => OP_HALT&"000000000000000000",
		
		--Ecuacion b) 10X^2 + 30X - Z/2
		96 => OP_LOAD&RA&x"00F8", --LOAD X,RA
		97 => OP_LOAD&RB&x"00F8", --LOAD X,RB
		98 => OP_MULT&RA&RB&RA&x"000",--MULT RA,RB,RA
		99 => OP_MULTI&RA&x"000A", --MULTI RA,10
		100=> OP_LOAD&RB&x"00F8", --LOAD X,RB
		101=> OP_MULTI&RB&x"001E",--MULTI RB,30
		102=> OP_LOAD&RC&x"00FA", --LOAD Z,RC
		103=> OP_DIVI&RC&x"0002", --DIVI RC,2
		104=> OP_ADD&RA&RB&RA&x"000",--ADD RA,RB,RA
		105=> OP_SUB&RA&RC&RA&x"000",--SUB RA,RC,RA
		106=> OP_DPLY&RA&x"0000",--DPLY RA
		107=> OP_JMP&"00"&x"0009",
		--Ecuacion c) -X^3 - 7Z +W/10
		108 => OP_LOAD&RA&x"00F8", --LOAD X,RA
		109 => OP_LOAD&RB&x"00F8", --LOAD X,RB
		110 => OP_MULT&RA&RB&RA&x"000",--MULT RA,RB,RA
		111 => OP_MULT&RA&RB&RA&x"000",--MULT RA,RB,RA
		112 => OP_LOAD&RB&x"00FA", --LOAD Z,RB
		113 => OP_MULTI&RB&x"0007",--MULTI RB,7
		114 => OP_LOAD&RC&x"00F7", --LOAD W,RC
		115 => OP_DIVI&RC&x"000A", --DIVI RC,10
		116 => OP_SUB&RC&RB&RB&x"000", --SUB RC,RB,RB
		117 => OP_SUB&RB&RA&RA&x"000", --SUB RB,RA,RA
		118=> OP_DPLY&RA&x"0000",--DPLY RA
		119=> OP_JMP&"00"&x"0009",
		--Ecuacion d) desplegar 0000 en el display
		120=> OP_LOAD&RA&x"00F5",
		121=> OP_DPLY&RA&x"0000",--DPLY RA
		122=> OP_HALT&"000000000000000000",
		241 => x"00002B",
		242 => x"00000A",-- T 10
		243 => x"000004",--4
		244 => x"00FFFF",-- j
		245 => x"000000",-- 0
		246 => x"000003",-- 30 en decimal i
		247 => x"000028", -- 40 en decimal W pra que sea divisible exacto del 10 y del 4
		248 => x"000001", -- 1 en decimal X
		249 => x"000002", -- 2 en decimal Y 
		250 => x"000003", -- 3 en decimal Z
		251 => x"000012", -- 18 en decimal M
		252 => x"000007", -- 7 en decimal N 
		253 => x"000017", -- 23 en decimal O 
		254 => x"000037", -- 55 en decimal P 
		255 => OP_HALT&"000000000000000000", --INICIO DEL PC
		others => x"000000"
	);
begin
	process(clk,clr,read_m,address)
	begin
		if(clr='1') then	
			data_out<=(others=>'Z');
		elsif(clk'event and clk='1') then
			if(enable='1') then 
				if(read_m='1') then
					data_out<=content(conv_integer(address));
				else
					data_out<=(others=>'Z');
				end if;
			end if;
		end if;
	end process;
end a_ROM;
