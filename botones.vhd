library ieee;
use ieee.std_logic_1164.all;

entity botones is port(
	push_buttons: in std_logic_vector(4 downto 0);
	buttons_out: out std_logic_vector(4 downto 0)
);
end botones;

architecture a_botones of botones is
	
	signal reg_push_buttons: std_logic_vector(4 downto 0):=(others=>'0');
begin
	
	process (push_buttons)
	begin
		case push_buttons is 
			when "00001"=>
				reg_push_buttons<="00001";
			when "00010"=>
				reg_push_buttons<="00010";
			when "00100"=>
				reg_push_buttons<="00100";
			when "01000"=>
				reg_push_buttons<="01000";
			when "10000"=>
				reg_push_buttons<="10000";
			when others=>
				reg_push_buttons<="00000";
		end case;
	end process;
	
	buttons_out<=reg_push_buttons;
end a_botones;