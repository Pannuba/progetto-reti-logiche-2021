library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
	port (
		i_clk		: in std_logic;
		i_rst		: in std_logic;
		i_start		: in std_logic;
		i_data		: in std_logic_vector(7 downto 0);
		o_address	: out std_logic_vector(15 downto 0);
		o_done		: out std_logic;
		o_en		: out std_logic;
		o_we		: out std_logic;
		o_data		: out std_logic_vector(7 downto 0)
	);

end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

	type state_type is (idle, get_width, get_height, calculate_image_size, check_image_size, set_read_address, set_o_address,
						read_pixel, find_max_min_pixel, calculate_delta_value, calculate_log_value,
						calculate_shift_level, calculate_temp_pixel, calculate_new_pixel, write_pixel, done);

	signal next_state, current_state:				state_type				:= idle;
	signal read_address, next_read_address:			unsigned(15 downto 0)	:= "0000000000000001";
	signal write_address, next_write_address:		unsigned(15 downto 0)	:= "0000000000000000";
	signal width, next_width:						unsigned(7 downto 0)	:= "00000000";
	signal height, next_height:						unsigned(7 downto 0)	:= "00000000";
	signal total_pixels, next_total_pixels:			unsigned(15 downto 0)	:= "0000000000000000";
	signal current_pixel, next_current_pixel:		unsigned(7 downto 0)	:= "00000000";
	signal min_pixel, next_min_pixel:				unsigned(7 downto 0)	:= "11111111";
	signal max_pixel, next_max_pixel:				unsigned(7 downto 0)	:= "00000000";
	signal temp_pixel, next_temp_pixel:				unsigned(15 downto 0)	:= "0000000000000000";
	signal new_pixel, next_new_pixel:				unsigned(7 downto 0)	:= "00000000";
	signal log_value, next_log_value:				unsigned(3 downto 0)	:= "0000";
	signal delta_value, next_delta_value:			unsigned(7 downto 0)	:= "00000000";
	signal shift_level, next_shift_level:			unsigned(4 downto 0)	:= "00000";
	signal first_scan_done, next_first_scan_done:	std_logic				:= '0';

begin

	state_reg: process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			current_state <= idle;

		elsif rising_edge(i_clk) then
			current_state		<= next_state;
			read_address		<= next_read_address;
			write_address		<= next_write_address;
			width				<= next_width;
			height				<= next_height;
			total_pixels		<= next_total_pixels;
			current_pixel		<= next_current_pixel;
			min_pixel			<= next_min_pixel;
			max_pixel			<= next_max_pixel;
			temp_pixel			<= next_temp_pixel;
			new_pixel			<= next_new_pixel;
			log_value			<= next_log_value;
			delta_value			<= next_delta_value;
			shift_level			<= next_shift_level;
			first_scan_done		<= next_first_scan_done;
		end if;
	end process;

	lambda_delta: process(	i_rst, i_clk, i_start, i_data, current_state, first_scan_done, read_address, write_address,
							width, height, total_pixels, current_pixel, min_pixel, max_pixel, new_pixel, log_value,
							temp_pixel, delta_value, shift_level)
	begin
		next_state				<= current_state;
		next_read_address		<= read_address;
		next_write_address		<= write_address;
		next_width				<= width;
		next_height				<= height;
		next_total_pixels		<= total_pixels;
		next_current_pixel		<= current_pixel;
		next_min_pixel			<= min_pixel;
		next_max_pixel			<= max_pixel;
		next_temp_pixel			<= temp_pixel;
		next_new_pixel			<= new_pixel;
		next_log_value			<= log_value;
		next_delta_value		<= delta_value;
		next_shift_level		<= shift_level;
		next_first_scan_done	<= first_scan_done;

		o_done <= '0';
		o_en <= '0';
		o_we <= '0';
		o_data <= "00000000";
		o_address <= std_logic_vector(read_address);

		case current_state is
			when idle =>
				o_address <= "0000000000000000";
				next_read_address <= "0000000000000001";
				next_min_pixel <= "11111111";
				next_max_pixel <= "00000000";
				next_first_scan_done <= '0';

				if i_start = '1' then
					o_en <= '1';
					next_state <= get_width;
				end if;

			when get_width =>
				o_en <= '1';
				o_address <= "0000000000000001";
				next_width <= unsigned(i_data);
				next_state <= get_height;

			when get_height =>
				next_height <= unsigned(i_data);
				next_state <= calculate_image_size;

			when calculate_image_size =>
				next_total_pixels <= width * height;
				next_state <= check_image_size;

			when check_image_size =>

				if total_pixels = 0 then
					next_state <= done;
				else
					next_state <= set_read_address;
				end if;

			when set_read_address =>
				next_read_address <= read_address + 1;
				next_state <= set_o_address;

			when set_o_address =>
				o_en <= '1';
				o_address <= std_logic_vector(read_address);
				next_state <= read_pixel;

			when read_pixel =>
				next_current_pixel <= unsigned(i_data);

				if first_scan_done = '1' then 
					next_state <= calculate_temp_pixel;
				else
					next_state <= find_max_min_pixel;
				end if;

			when find_max_min_pixel =>

				if current_pixel > max_pixel then
					next_max_pixel <= current_pixel;
				end if;

				if current_pixel < min_pixel then
					next_min_pixel <= current_pixel;
				end if;

				if read_address = (total_pixels + 1) then
					next_state <= calculate_delta_value;
				else
					next_state <= set_read_address;
				end if;

			when calculate_delta_value =>
				next_delta_value <= max_pixel - min_pixel;
				next_state <= calculate_log_value;

			when calculate_log_value =>

				if	   delta_value =  "00000000"									then next_log_value <= "0000";
				elsif (delta_value >= "00000001") and (delta_value <= "00000010")	then next_log_value <= "0001";
				elsif (delta_value >= "00000011") and (delta_value <= "00000110")	then next_log_value <= "0010";
				elsif (delta_value >= "00000111") and (delta_value <= "00001110")	then next_log_value <= "0011";
				elsif (delta_value >= "00001111") and (delta_value <= "00011110")	then next_log_value <= "0100";
				elsif (delta_value >= "00011111") and (delta_value <= "00111110")	then next_log_value <= "0101";
				elsif (delta_value >= "00111111") and (delta_value <= "01111110")	then next_log_value <= "0110";
				elsif (delta_value >= "01111111") and (delta_value <= "11111110")	then next_log_value <= "0111";
				elsif  delta_value =  "11111111"									then next_log_value <= "1000";
				end if;

				next_state <= calculate_shift_level;

			when calculate_shift_level =>
				next_read_address <= "0000000000000001";
				next_shift_level <= "01000" - resize(log_value, 5);
				next_first_scan_done <= '1';
				next_state <= set_read_address;

			when calculate_temp_pixel =>
				next_temp_pixel <= shift_left(resize(current_pixel, 16) - resize(min_pixel, 16), to_integer(shift_level));
				next_state <= calculate_new_pixel;

			when calculate_new_pixel =>

				if temp_pixel < "11111111" then
					next_new_pixel <= resize(temp_pixel, 8);
				else
					next_new_pixel <= "11111111";
				end if;

				next_write_address <= read_address + total_pixels;
				next_state <= write_pixel;

			when write_pixel =>
				o_en <= '1';
				o_we <= '1';
				o_address <= std_logic_vector(write_address);
				o_data <= std_logic_vector(new_pixel);

				if write_address = (total_pixels + total_pixels + 1) then
					next_state <= done;
				else
					next_state <= set_read_address;
				end if;

			when done =>
				o_done <= '1';
				next_state <= idle;

			end case;
	end process;
end Behavioral;
