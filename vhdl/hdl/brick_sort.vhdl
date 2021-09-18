library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity brick_sort is
  generic (
    DATA_WIDTH : natural := 8;
    NUM_ELEMS  : natural := 16
    );
  port (
    clk : in std_ulogic;
    rst : in stD_ulogic;

    src_tvalid : in std_ulogic;
    src_tready : out std_ulogic;
    src_tdata_raw  :  in std_ulogic_vector(DATA_WIDTH*NUM_ELEMS - 1 downto 0);

    dest_tvalid : out std_ulogic;
    dest_tready :  in std_ulogic;
    dest_tdata_raw  : out std_ulogic_vector(DATA_WIDTH*NUM_ELEMS - 1 downto 0)
    );
end entity brick_sort;

architecture rtl of brick_sort is

  type arr_type is array(NUM_ELEMS - 1 downto 0)
    of unsigned(DATA_WIDTH - 1 downto 0);

  signal src_tdata : arr_type;
  signal dest_tdata : arr_type;
  signal data_arr : arr_type;

  type sm_type is (SM_INIT, SM_SORT, SM_EJECT);
  signal sm : sm_type;
  signal sort_even : std_ulogic;
  function log2(val_cpy : natural) return natural is
    variable val : natural := val_cpy;
    variable retVal : natural := 0;
  begin
    while(val > 1) loop
      val := val / 2;
      retVal := retVal + 1;
    end loop;
    return retVal;
  end function;
  
  signal cnter : unsigned(log2(2*NUM_ELEMS+1) downto 0);
  constant even_cap : natural := (NUM_ELEMS+1)/2 - 2;
  constant odd_cap : natural := NUM_ELEMS/2 - 1;

  signal dest_tvalid_cpy : std_ulogic;
  signal src_tready_cpy : std_ulogic;
begin
  dest_tvalid <= dest_tvalid_cpy;
  src_tready <= src_tready_cpy;

  raw_tdata_gen : for i in 0 to NUM_ELEMS - 1 generate

    dest_tdata_raw((i+1)*DATA_WIDTH - 1 downto i * DATA_WIDTH)
      <= std_ulogic_vector(dest_tdata(i));

    src_tdata(i)
      <= unsigned(src_tdata_raw((i+1)*DATA_WIDTH - 1 downto i * DATA_WIDTH));
    
    dest_tdata(i) <= data_arr(i);
  end generate;

  dest_tvalid_cpy <= not rst when sm = SM_EJECT else '0';
  src_tready_cpy <= not rst when sm = SM_INIT else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      
      if (src_tvalid = '1' and src_tready_cpy = '1') then
        for i in 0 to NUM_ELEMS - 1 loop
          data_arr(i) <= src_tdata(i);
        end loop;
      end if;

      case (sm) is
        when SM_INIT =>
          if (src_tvalid = '1' and src_tready_cpy = '1') then
            sm <= SM_SORT;
          else
            sm <= SM_INIT;
          end if;
        when SM_SORT =>
          if (cnter = 2 * NUM_ELEMS) then
            sm <= SM_EJECT;
          else
            sm <= SM_SORT;
          end if;
        when SM_EJECT =>
          if (dest_tvalid_cpy = '1' and dest_tready = '1') then
            sm <= SM_INIT;
          end if;
      end case;

      case (sm) is
        when SM_INIT  => sort_even <= '0';
        when SM_SORT  => sort_even <= not sort_even;
        when SM_EJECT => sort_even <= '0';
      end case;

      case (sm) is
        when SM_INIT  => cnter <= (others => '0');
        when SM_SORT  => cnter <= cnter + 1;
        when SM_EJECT => cnter <= (others => '0');
      end case;

      if (sm = SM_SORT) then
        if (sort_even = '1') then
          for i in 0 to even_cap loop
            if (data_arr(2*i+1) > data_arr(2*i + 2)) then
              data_arr(2*i + 2) <= data_arr(2*i+1);
              data_arr(2*i+1) <= data_arr(2*i + 2);
            end if;
          end loop;
        else
          for i in 0 to odd_cap loop
            if (data_arr(2*i) > data_arr(2*i + 1)) then
              data_arr(2*i + 1) <= data_arr(2*i);
              data_arr(2*i) <= data_arr(2*i + 1);
            end if;
          end loop;
        end if;
      end if;

      if (rst = '1') then
        sm <= SM_INIT;
        sort_even <= '0';
        cnter <= (others => '0');
      end if;
      
    end if;
  end process;
  
end architecture rtl;

    
