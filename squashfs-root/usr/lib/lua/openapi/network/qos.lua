LuaQ               F      E@    ÅÀ   AA  E  \  ÁÁ  Å  Ü  AB  FB\ Â Á C CBÂ Á C d       G dC       GÃ d    G dÃ    GC d   G dC         GÃ d G dÃ               GC d            G dC    GÃ         os    ipairs    table    string    require 	   nixio.fs    luci.tools.json 
   luci.util    openapi.utils.utils    luci.model.uci    cursor    module    openapi.network.qos    package    seeall 	  	   	c      set_bw    get_bw    start    stop    restart    set_qos    hwf_sqos_setup_tc_qdisc    get_part_speedup_list    set_part_speedup    cancel_part_speedup 
          $    -   E      \ W@À @D   FÀ À  Á  A \@ FA Z@    AÀ  B @    À Ä  Æ@Â @ Á Ü@ Ä  Æ@Â @ Á Ü@ Ä  Æ@ÂA Ü@ Ä   ÆÀ AÁ A Ý  Þ           type    table    ret_output    1    data type error        up    4000    down    exec "   uci set smartqos.@smartqos[0].up=     2>/dev/null $   uci set smartqos.@smartqos[0].down=    uci commit smartqos    0    set_bw success                     &   0        
   D   F À @  \     @Á   Ä   Æ Á  Ü 	ÀÄ   Æ Á  Ü 	ÀÄ  ÆÁÁ A   Ý  Þ     	      exec -   uci get smartqos.@smartqos[0].up 2>/dev/null /   uci get smartqos.@smartqos[0].down 2>/dev/null    up    trim    down    ret_output    0    get_bw success                     2   5            @ A@  @    @ AÀ    Á@              exec    /etc/init.d/smartqos start    ret_output    0    start success                         7   :            @ A@  @    @ AÀ    Á@              exec    /etc/init.d/smartqos stop    ret_output    0    stop success                         <   ?            @ A@  @    @ AÀ    Á@              exec    /etc/init.d/smartqos restart    ret_output    0    restart success                         E   ®     #     A@   D   FÀ À   A@AÁ   \  À   A@AÁÀ  ÅÀ  Æ ÁÆ@Á Ü A EÁ  FÁFAÁ \   EA Á  AAAÁÁ  \  Á  AAAÁ  Å  B Ü WC@WÀCÀÂ  DBD@   Â  DD@   Â AÂ   ÆÅ  Ü ÚB  @ B  1ÅB   Ü Ú  /ÅB  Ü Ú  @.Å   Ü   AÃ  D FÆC \   WÃÀÄ  ÆÆ AÄ ÜÀ ÆÇ  @ 	ÜDáC  @þÂ  DÇ@  J  WC@ ÀD  Á WÃ@ ÀÄ  AÁ D À  D À @Ä  D	ÄG	Á   AE ÁE   AF ÁF   A ÕD	D Ä À  ËIAF	 ÜE@ ÔÌÉ  AG ÁG   AH  IÂ  ÔÌÉI¡   úÚC  I	À E @E À F @ ÕD	IÄ	 ÄI	Ä ÆÊ	E Ü D   DJ	ÅD  J
@Å
 D  GÀ  @ D D À  G	D À G	@Ä  D	ÄG	Á   AE ÁE   A ÕD	D Ä À ÀËIAF ÜW@ II¡  @ý ÄI	Ä ÆÊ	E Ü D   DJ	ÅD  J
@Å
 D  KÀ D  Â   Â ÀD  @ÅÂ  ÆÄÆÌ  Ü @BÆÂL   ÜB   4      require 
   luci.http    upper    luci    http 
   formvalue    mac    up    down 	   tonumber    guaranty_up    guaranty_down    name    luci.cbi.datatypes         util    trim    filter_htmltags 	       macaddr 		     hiwifi.collection.sets    hiwifi.device_qos_guaranty 	   readfile    DEVICE_QOS_FILE    gmatch    [^
]+    add    to_list 	ÿÿÿÿ   exec    echo "          " >/proc/net/smartqos/config    pairs    match -   ^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s%s]+) 	      mkdirr    dirname 
   writefile    concat    
 $    -1 -1 " >/proc/net/smartqos/config     ^([^%s]+)%s+([^%s]+)%s+([^%s]+)    del 	&     get_api_error    code    msg    write_json                     ³   µ            @@ @ AÀ    @        luci    util    delay_exec J   source /lib/functions/hwf_sqos_tc_actions.sh && hwf_sqos_setup_tc_qdisc & 	                       ¸      |   F @ @  Á  
  J  @@@  	  A ÅA  Ü 
  FÂÁ\ Z    À ÆBDB	¡  þ ÅB  Ü ÃÂ D FÃ ä     \CEC C \ ÃÃ  D  \@Â
  À Â
@@ Ä @ Â
Å@Ê  Å
Å@ÆÂ
ÅÅ@ÆEÄ
ÅÅ@Å@ÅDÅ@ÄÅÅ@ÄÅÅ@E@  À ÅEÀ  Ä ÆÅÅÂ
Ü À@Å@ÅÅ@Fa  Àð£     AFÀ  À    Á          ios_client_ver 	           list    get_device_list_brief    require    hiwifi.net    get_dhcp_client_list    mac    name    hiwifi.device_names    get_all    foreach    hiwifi.mobileapp.part_speedup    get_device_speedup    æªç¥    item_id    rpt    icon "   http://s.hiwifi.com/m/pc_icon.png    time_total 
   time_over    status    lower 	      get_api_error    data    code    msg        Ú   Ü          @                                          $      F @ @@ Á  Á  J    Å B Ü Á@   Ä  BÀ   ÂA@   IÁ II^         ios_client_ver    item_id 	           require    hiwifi.mobileapp.part_speedup    set_device_speedup    get_api_error    code    msg    data                     '  B   
   F @ @@ Á  Á  J    Å B Ü Á@ B À     ÂA@   Á A         ios_client_ver    item_id 	           require    hiwifi.mobileapp.part_speedup    cancel_device_speedup    get_api_error    code    msg    data                             