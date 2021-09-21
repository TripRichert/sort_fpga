library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity insertion_sort is
  generic (
    DATA_WIDTH : natural := 8;
    ADDR_WIDTH : natural := 12
    );
  port (
    clk : in std_ulogic;
    rst : in std_ulogic;

    src_tvalid  :  in std_ulogic;
    src_tready  : out std_ulogic;
    src_tdata   :  in std_ulogic_vector(DATA_WIDTH - 1 downto 0);
    src_tlast   :  in std_ulogic;

    dest_tvalid : out std_ulogic;
    dest_tready :  in std_ulogic;
    dest_tdata  : out std_ulogic_vector(DATA_WIDTH - 1 downto 0);
    dest_tlast  : out std_ulogic;

    tlast_err   : out std_ulogic
    );
end entity insertion_sort;

architecture rtl of insertion_sort is

  signal dest_tvalid_cpy : std_ulogic;
  signal src_tready_cpy  : std_ulogic;
  signal dest_tlast_cpy  : std_ulogic;

  type arr_type is array(2**ADDR_WIDTH - 1 downto 0)
    of std_ulogic_vector(DATA_WIDTH - 1 downto 0);
  signal data_buf : arr_type;

  type sm_type is (SM_SORT, SM_EJECT);
  signal sm : sm_type;

  signal cnt : unsigned(ADDR_WIDTH downto 0);
  signal tlast : std_ulogic;

begin
  src_tready <= src_tready_cpy;
  dest_tvalid <= dest_tvalid_cpy;
  dest_tlast <= dest_tlast_cpy;
  
  tlast <= src_tvalid when (cnt = 2**ADDR_WIDTH - 1 and sm = SM_SORT) else
           src_tlast;
  tlast_err <= tlast and not src_tlast and src_tvalid and src_tready_cpy;

  src_tready_cpy <= not rst when sm = SM_SORT else '0';
  dest_tvalid_cpy <= not rst when sm = SM_EJECT else '0';
  dest_tdata <= data_buf(0);
  dest_tlast_cpy <= dest_tvalid_cpy when sm = SM_EJECT and cnt = 1 else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      if src_tvalid = '1' and src_tready_cpy = '1' then
        case sm is
          when SM_SORT =>
            if (cnt = 0) then
              data_buf(0) <= src_tdata;
            elsif(data_buf(0) > src_tdata) then
              data_buf(0) <= src_tdata;
            else
              data_buf(0) <= data_buf(0);
            end if;
            for i in 1 to data_buf'length - 1 loop
              if (i < cnt) then
                if (data_buf(i - 1) >= src_tdata) then
                  data_buf(i) <= data_buf(i - 1);
                elsif (data_buf(i) >= src_tdata) then
                  data_buf(i) <= src_tdata;
                else
                  data_buf(i) <= data_buf(i);
                end if;
              elsif (i = cnt) then
                if (data_buf(i - 1) >= src_tdata) then
                  data_buf(i) <= data_buf(i - 1);
                else
                  data_buf(i) <= src_tdata;
                end if;
              else
                data_buf(i) <= data_buf(i);
              end if;
            end loop;
          when SM_EJECT =>
            for i in 1 to data_buf'length - 1 loop
              data_buf(i) <= data_buf(i);
            end loop;
        end case;
      elsif (dest_tvalid_cpy = '1' and dest_tready = '1') then
        for i in 0 to data_buf'length- 2 loop
          data_buf(i) <= data_buf(i + 1);
        end loop;
        data_buf(data_buf'length - 1) <= data_buf(data_buf'length - 1);
        
      else
        for i in 0 to 2**ADDR_WIDTH - 1 loop
          data_buf(i) <= data_buf(i);
        end loop;
      end if;

      if (src_tvalid = '1' and src_tready_cpy = '1' and
          not (dest_tvalid_cpy = '1' and dest_tready = '1')) then
        cnt <= cnt + 1;
      elsif (not (src_tvalid = '1' and src_tready_cpy = '1') and
             dest_tvalid_cpy = '1' and dest_tready = '1') then
        if cnt = 0 then
          cnt <= (others => '0');
        else
          cnt <= cnt - 1;
        end if;
      else
        cnt <= cnt;
      end if;

      case sm is
        when SM_SORT =>
          if (src_tvalid = '1' and src_tready_cpy = '1' and tlast = '1') then
            sm <= SM_EJECT;
          else
            sm <= SM_SORT;
          end if;
        when SM_EJECT =>
          if (dest_tvalid_cpy = '1' and dest_tready = '1' and dest_tlast_cpy = '1') then
            sm <= SM_SORT;
          else
            sm <= SM_EJECT;
          end if;
      end case;

      if (rst = '1') then
        cnt <= (others => '0');
        sm <= SM_SORT;
      end if;
    end if;
  end process;
  
end architecture rtl;
