library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------
library machxo2;
use machxo2.all; 
----------------------------------------------------------
entity alu_fetch is port(
	reset: in std_logic;
	stop_run: in std_logic;
	SW: in std_logic_vector(1 downto 0);
	display: out std_logic_vector(6 downto 0);
	signo: out std_logic;
	sel: out std_logic_vector(3 downto 0)
);
end alu_fetch;

architecture behavior of alu_fetch is
----------OSCILADOR INTERNO-------------------------------
    component OSCH
        generic (NOM_FREQ: string);
        port (STDBY: in std_logic; OSC: out std_logic);
    end component;
    
    attribute NOM_FREQ: string;
    attribute NOM_FREQ of OSCinst0: label is "3.02";
----------------------------------------------------------
	component ROM is port(
		clk: in std_logic;
		clr: in std_logic;
		enable: in std_logic;
		read_m : in std_logic; 
		address: in std_logic_vector(7 downto 0);
		data_out : out std_logic_vector(23 downto 0)
	);
	end component;
		
	component registrosPG is Port ( 
		clk        : in  STD_LOGIC;
		reset      : in  STD_LOGIC;
		enable     : in  STD_LOGIC;
		data_in    : in  STD_LOGIC_VECTOR (23 downto 0);
		selector1  : in  STD_LOGIC_VECTOR (1 downto 0); 
		data_out1  : out STD_LOGIC_VECTOR (23 downto 0));
	end component;

	
	component bcdDisplay is port(
		CLK,CLR: IN STD_LOGIC;
		E: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		DISPLAY:INOUT STD_LOGIC_VECTOR(6 DOWNTO 0)	
		);
	end component;

	component Bin2BCD is port(
		clr: in std_logic;
        bin_in : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
        bcd_out   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
	end component;
	
	component alu is port(
		clk: in std_logic;
		reset: in std_logic;
		A,B: in std_logic_vector(15 downto 0);
		control: in std_logic_vector(3 downto 0);
		result: out std_logic_vector(15 downto 0);
		C,Z,S,V,end_div: out std_logic);
	end component;
	
signal clk: std_logic;
signal clk_0: std_logic:='0';
signal clk_1: std_logic:='0';
signal Q: std_logic_vector(13 downto 0);
signal Qbcd: std_logic_vector(15 downto 0);
signal temp_control: std_logic_vector(3 downto 0);
signal un,de,ce,mi: std_logic_vector(6 downto 0);
signal Rdisplay: std_logic_vector(13 downto 0);
--REGISTROS PARA DATAPATH--
signal PC: std_logic_vector(7 downto 0):=(others=>'0');
signal PC_mux : std_logic_vector(7 downto 0):=(others=>'0');
signal MAR: std_logic_vector(7 downto 0):=(others=>'0');
signal MBR: std_logic_vector(23 downto 0):=(others=>'0');
signal IR: std_logic_vector(23 downto 0):=(others=>'0');
signal ACC: std_logic_vector(15 downto 0):=(others=>'0');

--entradas,salidas componentes
signal data_bus: std_logic_vector(23 downto 0);
signal rpg_in: std_logic_vector(23 downto 0):=(others=>'0');
signal rpg_out1: std_logic_vector(23 downto 0);
signal rpg_sel1: std_logic_vector(1 downto 0):=(others=>'0');
--signal rpg_out2: std_logic_vector(23 downto 0);
--signal rpg_sel2: std_logic_vector(1 downto 0):=(others=>'0');
signal rpg_write: std_logic:='0';
signal A,B: std_logic_vector(15 downto 0);
signal control: std_logic_vector(3 downto 0);
signal C,Z,S,V,end_div: std_logic;
signal reset_div: std_logic:='0';
type global_state_type is (reset_pc,fetch,fetch1,fetch2,fetch3,end_fetch,decode,end_decode, execute,end_execute); 
signal global_state: global_state_type;

type instruction_type is (i_nop,i_load,i_addi,i_dply,i_adec,i_bnz,i_bz,i_bs,i_bns,i_null,i_bnc,i_bc,i_bnv,i_bv,
i_halt,i_add,i_sub,i_mult,i_div,i_multi,i_divi,i_comp1,i_comp2,i_jmp,i_loadi,i_cmp,i_cmpi,i_jr,i_ja);

signal instruction: instruction_type;

type execute_instruction_type is(t0,t1,t2,t3,t4,t5);
signal execute_instruction: execute_instruction_type;


begin
-----------IMPLEMENTACION OSCILADOR INTERNO---------------
OSCinst0: OSCH generic map("3.02") port map('0', clk);
----------------------------------------------------------
imp_binBCD: bin2bcd port map(reset,Q,Qbcd);
--clk_0
unidades: bcdDisplay port map(clk_0,reset,Qbcd(3 downto 0),un);
decenas: bcdDisplay port map(clk_0,reset,Qbcd(7 downto 4),de);
centenas: bcdDisplay port map(clk_0,reset,Qbcd(11 downto 8),ce);
millar: bcdDisplay port map(clk_0,reset,Qbcd(15 downto 12),mi);
--clk_1
ROM_imp: ROM port map(clk_1,reset,'1','1',MAR,data_bus);
RPG : registrosPG port map(clk_1,reset,rpg_write,rpg_in,rpg_sel1,rpg_out1);
ALU_imp : alu port map(clk_1,reset_div,A,B,control,ACC(15 downto 0),C,Z,S,V,end_div);

process(clk_1, reset, stop_run)
	begin
		if (reset = '1') then
			PC<= PC_mux;
			global_state <= reset_pc;
			execute_instruction<=t0;
			MAR<=(others=>'0');
			MBR<=(others=>'0');
			IR<=(others=>'0');				
		elsif (rising_edge(clk_1) and stop_run='0') then			
			case global_state is
				when reset_pc=>
					global_state<=fetch;
				when fetch =>
					MAR<=PC;
					global_state<=fetch1;
				when fetch1 =>
					global_state<=fetch2;--sincronizar data_bus 
				when fetch2 => 
					MBR<=data_bus;
					global_state<=fetch3;
				when fetch3=>
					PC<=PC+1;
					IR<=MBR;
					global_state<=end_fetch;
				when end_fetch=>
					global_state<=decode;
				when decode =>
					case IR(23 downto 18) is
						when "000000" =>instruction <= i_nop;
						when "000001" =>instruction <= i_load;
						when "000010" =>instruction <= i_addi;
						when "000011" =>instruction <= i_dply;
						when "000100" =>instruction <= i_adec;
						when "000101" =>instruction <= i_bnz;
						when "000110" =>instruction <= i_bz;
						when "000111" =>instruction <= i_bs;
						when "001000" =>instruction <= i_bns;
						when "001001" =>instruction <= i_bnc;
						when "001010" =>instruction <= i_bc;
						when "001011" =>instruction <= i_bnv;
						when "001100" =>instruction <= i_bv;
						when "001101" =>instruction <= i_halt;
						when "001110" =>instruction <= i_add;
						when "011111" =>instruction <= i_sub;
						when "010000" =>instruction <= i_mult;
						when "010001" =>instruction <= i_div;
						when "010010" =>instruction <= i_multi;
						when "010011" =>instruction <= i_divi;
						when "010100" =>instruction <= i_comp1;
						when "010101" =>instruction <= i_comp2;
						when "010110" =>instruction <= i_jmp;
						when "010111" =>instruction <= i_loadi;
						when "011000" =>instruction <= i_cmp;	
						when "011001" =>instruction	<= i_cmpi;
						when "011010" =>instruction <= i_jr;
						when "011011" =>instruction <= i_ja;
						when others =>
							instruction <= i_null;
					end case;
					global_state<=end_decode;
					
				when end_decode=>
					global_state<=execute;
					
				when execute =>
					case instruction is
						when i_nop =>
							global_state<=end_execute;
							
						when i_load =>
							case execute_instruction is 
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									MAR<=IR(7 downto 0);
									execute_instruction<=t2;
								when t2 =>
									execute_instruction<=t3;--sincronizar data_bus
								when t3 =>
									rpg_write<='1';
									rpg_sel1<=IR(17 downto 16);
									rpg_in<=data_bus;
									execute_instruction<=t4;
								when t4 =>
									rpg_write<='0';
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
							
						when i_loadi =>
							case execute_instruction is 
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_write<='1';
									rpg_sel1<=IR(17 downto 16);
									rpg_in<="00000000"&IR(15 downto 0);
									execute_instruction<=t2;
								when t2 =>
									rpg_write<='0';
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
							
						when i_addi =>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel1<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>
									control<="0110";
									A<=rpg_out1(15 downto 0);
									B<=IR(15 downto 0);
									execute_instruction<=t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="0000000"&C&ACC;
									else
										rpg_in<="00000000"&ACC;
									end if;
									execute_instruction<=t4;
								when t4 =>
									rpg_write<='0';
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
						when i_multi => 
							case execute_instruction is 
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel1<=IR(17 downto 16);
									execute_instruction <= t2;
								when t2 =>
									control <= "1101";
									A <= rpg_out1(15 downto 0); 
									B <= IR(15 downto 0);
									execute_instruction <= t3;
								when t3 =>
									rpg_write<='1';
									rpg_in <= "00000000"&ACC;
									execute_instruction <= t4;
								when t4 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;									
							end case;
						when i_divi => 
							case execute_instruction is 
								when t0 =>
									reset_div<='1';
									execute_instruction<=t1;
								when t1 =>
									reset_div<='0';
									rpg_sel1<=IR(17 downto 16);
									execute_instruction <= t2;
								when t2 =>
									control <= "1110";
									A <= rpg_out1(15 downto 0); 
									B <= IR(15 downto 0); 
									if(end_div = '1') then
										execute_instruction <= t3;
									else
										execute_instruction <= t2;
									end if;
								when t3 =>
									rpg_write<='1';
									rpg_in <= "00000000"&ACC;
									execute_instruction <= t4;
								when t4 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;

						when i_add =>
							case execute_instruction is
								when t0 =>
									control <= "0110";
									rpg_sel1 <= IR(17 downto 16);
									execute_instruction <= t1;
								when t1 =>
									A<=rpg_out1(15 downto 0);
									execute_instruction <= t2;
								when t2 =>
									rpg_sel1 <= IR(15 downto 14);
									execute_instruction <= t3;
								when t3 =>
									B<=rpg_out1(15 downto 0);
									rpg_sel1 <= IR(13 downto 12);
									execute_instruction <= t4;
									rpg_write <= '1';
								when t4 =>
									if(C = '1') then
										rpg_in<="0000000"&C&ACC;
									else
										rpg_in<="00000000"&ACC;
									end if;
									execute_instruction <= t5;
								when t5 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_execute;
							end case;
						when i_sub =>
							case execute_instruction is
								when t0 =>
									control <= "0111";
									rpg_sel1 <= IR(17 downto 16);
									execute_instruction <= t1;
								when t1 =>
									A<=rpg_out1(15 downto 0);
									execute_instruction <= t2;
								when t2 =>
									rpg_sel1 <= IR(15 downto 14);
									execute_instruction <= t3;
								when t3 =>
									B<=rpg_out1(15 downto 0);
									rpg_sel1 <= IR(13 downto 12);
									execute_instruction <= t4;
									rpg_write <= '1';
								when t4 =>
									if(C = '1') then
										rpg_in<="0000000"&C&ACC;
									else
										rpg_in<="00000000"&ACC;
									end if;
									execute_instruction <= t5;
								when t5 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_execute;
							end case;
						when i_mult =>
							case execute_instruction is
								when t0 =>
									control <= "1101";
									rpg_sel1 <= IR(17 downto 16);
									execute_instruction <= t1;
								when t1 =>
									A<=rpg_out1(15 downto 0);
									execute_instruction <= t2;
								when t2 =>
									rpg_sel1 <= IR(15 downto 14);
									execute_instruction <= t3;
								when t3 =>
									B<=rpg_out1(15 downto 0);
									rpg_sel1 <= IR(13 downto 12);
									execute_instruction <= t4;
									rpg_write <= '1';
								when t4 =>
									if(C = '1') then
										rpg_in<="0000000"&C&ACC;
									else
										rpg_in<="00000000"&ACC;
									end if;
									execute_instruction <= t5;
								when t5 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_execute;
							end case;
						
						when i_dply=>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel1<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>--sincronizar  data_out;
									execute_instruction<=t3;
								when t3 =>
									if(rpg_out1(15) = '1') then
										A<=rpg_out1(15 downto 0);
										control<="1100";
										signo<='1';
									else
										signo<='0';
										Rdisplay<=rpg_out1(13 downto 0);
									end if;
									execute_instruction<=t4;
								when t4 =>
									if(rpg_out1(15) = '1') then 
										Rdisplay<=ACC(13 downto 0);
									end if;
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
						
						when i_adec =>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel1<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>
									control<=IR(3 downto 0);
									A<="0000"&rpg_out1(11 downto 0);
									execute_instruction<=t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="0000000"&C&ACC;
									else
										rpg_in<="00000000"&ACC;
									end if;
									execute_instruction<=t4;
								when t4 =>
									rpg_write<='0';
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;	
							end case;
					
						when i_bnz =>
							if(Z = '0') then
								if(IR(17)='0') then
									PC<=IR(7 downto 0);
								else
									PC<=PC+IR(7 downto 0)-1;
								end if;
								global_state<=end_execute;
							else
								global_state<=end_execute;
							end if;
						when i_bz =>
							if(Z = '1') then
								if(IR(17)='0') then
									PC<=IR(7 downto 0);
								else
									PC<=PC+IR(7 downto 0)-1;
								end if;
								global_state<=end_execute;
							else
								global_state<=end_execute;
							end if;
						when i_bns =>
							if(S = '0') then
								if(IR(17)='0') then
									PC<=IR(7 downto 0);
								else
									PC<=PC+IR(7 downto 0)-1;
								end if;
								global_state<=end_execute;
							else
								global_state<=end_execute;
							end if;
						when i_bs =>
							if(S = '1') then
								if(IR(17)='0') then
									PC<=IR(7 downto 0);
								else
									PC<=PC+IR(7 downto 0)-1;
								end if;
								global_state<=end_execute;
							else
								global_state<=end_execute;
							end if;
						when i_halt =>
							PC<=PC-1;
							global_state<=end_execute;
							
						when i_jmp =>
							if(IR(17)='0') then
								PC<=IR(7 downto 0);
							else
								PC<=PC+IR(7 downto 0)-1;
							end if;
							global_state<=end_execute;

						when i_cmp =>
							case execute_instruction is
								when t0 =>
									control <= "0111";
									rpg_sel1 <= IR(17 downto 16);
									execute_instruction <= t1;
								when t1 =>
									A<=rpg_out1(15 downto 0);
									execute_instruction <= t2;
								when t2 =>
									rpg_sel1 <= IR(15 downto 14);
									execute_instruction <= t3;
								when t3 =>
									B<=rpg_out1(15 downto 0);
									execute_instruction <= t4;
								when t4 =>
									execute_instruction <= t0;
									global_state <= end_execute;
								when others =>
									execute_instruction <= t0;
									global_state <= end_execute;
							end case;
						when i_cmpi =>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel1<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>
									control<="0111";
									A<=rpg_out1(15 downto 0);
									B<=IR(15 downto 0);
									execute_instruction<=t3;
								when t3 =>
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction <= t0;
									global_state <= end_execute;
							end case;
						when i_jr =>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel1<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>
									PC<=rpg_out1(7 downto 0);
									execute_instruction<=t3;
								when t3 =>
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction <= t0;
									global_state <= end_execute;
							end case;
						when i_ja =>
							if(S = '0' and Z = '0') then
								if(IR(17)='0') then
									PC<=IR(7 downto 0);
								else
									PC<=PC+IR(7 downto 0)-1;
								end if;
								global_state<=end_execute;
							else
								global_state<=end_execute;
							end if;							
						when others =>
							global_state<=end_execute;
					end case;
				when end_execute=>
					global_state<=fetch;
				when others =>
					global_state<=reset_pc;
			end case;
		end if;
	end process;

	Q<=Rdisplay;	
process(clk_0, reset)
	begin
		if (reset = '1') then
			temp_control <= "0000";
		elsif (rising_edge(clk_0)) then
			case temp_control is
				when "0000"=>
					temp_control <= "0001";
				when "0001"=> 
					temp_control <= "0010";
					display <= mi;
				when "0010"=> 
					temp_control <= "0100";
					display <= ce;
				when "0100"=> 
					temp_control <= "1000";
					display <= de;
				when "1000"=> 
					temp_control <= "0001";
					display <= un;
				when others=>
					temp_control <= "0000";
			end case;
			sel <= temp_control;
		end if;
end process;


process(clk, reset)
	variable count: integer range 0 to 2500;
	variable count1: integer range 0 to 25;
	begin
		if (reset = '1') then
			clk_0<= '0';
			clk_1<= '0';
		elsif (rising_edge(clk)) then
			if (count < 1000) then
				count := count + 1;
			else
				count := 0;
				clk_0 <= not clk_0;
			end if;
			
			if (count1 < 1) then
				count1 := count1 + 1;
			else
				count1 := 0;
				clk_1 <= not clk_1;
			end if;
		end if;
end process;



process(SW)
    begin
        case SW is
            when "00" =>
                PC_mux <= x"00";
            when "01" =>
                PC_mux <= x"60"; 
            when "10" =>
                PC_mux <= x"6C"; 
            when "11" =>
                PC_mux <= x"78"; 
            when others =>
                PC_mux <= x"00"; 
        end case;
end process;

end behavior;
