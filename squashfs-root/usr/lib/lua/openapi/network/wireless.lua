LuaQ               F      E@    ÅÀ   EA  \ A ÁÁ  ÅA  Ü B AB  B   ÁÂ  CCB¤        ¤B     Â ¤        ¤Â       B ¤     ¤B Â ¤  ¤Â    B ¤         ¤B    Â ¤         ¤Â       B ¤                  	   tostring 	   tonumber    os    ipairs    table    require    luci.tools.json 
   luci.util 
   luci.http    socket.http    module    openapi.network.wireless    package    seeall    debug 	   set_ssid 	   get_wifi    device_list    set_status    on    off    restart 
   get_txpwr 
   set_txpwr    get_channel    set_channel    get_channel_rank        
          D    À À D  F@À    \@         logger                        0    :   E   @  \@ E      \@ J   @ WÀ@@  AÀ IÁI ÂIÀÀ^  Å Á Ü Æ ÃÜ  AA  KC\ FÁÃFÄA UÄ ËÁDA   ÜA ËÅAB ÜAËÅAB ÜAÄ  ÆÁÅ ÜA I@ÆIÆIÀÀÅ    ÜA Å  Â ÜA ^          debug 1   ==================== set_ssid in ===============    ssid         code    10125    msg    data type error    data    require    luci.model.network    init    luci.tools.status    wifi_networks 	      device 
   .network1    get_wifinet    set    commit 	   wireless    save    execute    /usr/sbin/hwf-at 1 wifi    0    set_ssid success 2   ==================== set_ssid out ===============                     2   F           A@  @   AÀ     Á    AA@Á  AÀ  ÆÁA  @À          debug 1   ==================== get_ssid in =============== 	        8   http://127.0.0.1/cgi-bin/turbo/api/wifi/get_status_list    request    Decode    device_status    code    msg    data                     H   \           A@  @   AÀ     Á    AA@Á  AÀ  ÆÁA  @À          debug 8   ==================== get_device_list in =============== 	        7   http://127.0.0.1/cgi-bin/turbo/api/network/device_list    request    Decode    devices    code    msg    data                     ^   {    "   F @ @  Á  
  EÁ   \ W@À @ @Á  ÁA ÀWÀÁ @  Â  AÂA    @@     ÁBÀ  À  	 	Á         status 	           require    hiwifi.net    0    turn_wifi_off 	      1    turn_wifi_on 	      get_api_error    code    msg                                    J@  IÀ             set_status    status 	                                      J@  IÀ             set_status    status 	                           §     !      A@      @    Ä   ÆÀ   Ü @  @ Å@  Ü ÁÁ A  @  BAA  A   BAÁ  A       	           get_api_error    code    msg    require    hiwifi.net    get_wifi_bridge    delay_exec "   env -i /sbin/wifi >/dev/null 2>&1 	   &   env -i /sbin/ifup wan >/dev/null 2>&1                     ­   Ò    +   F @   Á@    J    ÅÁ   Ü ÆAÁÜ Á   ÀKÂA\  Â@D  BB \    Á   ÁÀ @À@ I D FÃ\  ÁA         device 	           require    luci.model.network    init    get_wifinet    active_mode    Master    txpwr 	è  	     get_api_error    code    msg    data                     Ø      =   F @ @@ Á  Á  J    AÀ B ÆAÂ A  BB KBÀ\Z  ÂÂC  @ B CC BCC BÂ ÁÂ  ÆDÜ ÚB   Ä  ÆBÄ  ÜB @Ä  ÆÄ  ÜB   ÁÀ À     EÀ   IÁI^         device    txpwr 	           split    . 	      require    luci.model.network    init    get_wifidev    set    commit 	   wireless    save    hiwifi.net    get_wifi_bridge    delay_exec_wifi    delay_exec_ifwanup 	     get_api_error    code    msg                       I   `   F @  A  A    Ê  B  EÂ   \ FBÁ\ Á    ÀËÂAÜ  Â@Ä  CB Ü       Á ÅÂ   Ü Ã  AC  FÃ\ ÃÃ AD  ÆÃDÜ Å   B @@ EEÄ  Ä \ D Á ÅÃ@ 		WF@ @ EÄ  D \ Ä  ÁÄ  ÆÄÄÜ EÅ	A ÅC	À 
 
   D FÄÆ \ @ÉÉAÉÞ          device 	           require    luci.model.network    init    get_wifinet    active_mode    Master    channel 	è  	     luci.model.uci    hiwifi.net    cursor    get    network    wan    ifname    get_wifi_ifnames 	   	      0    hcwifi    ch    channel_autoreal     get_api_error 
   is_bridge    code    msg    data                     N     P   F @ @@ Á  Á  J    AÀ B ÆAÂ A  BB KBÀ\Z  @ À    	 À  À À  ÀBÃC  @ B BC BÂC BÂ Á  ÆBDÜ ÚB   Ä  ÆÄÃ ÜB @Ä  ÆÅÃ ÜB  Á@  Á@   Á À     ÂEÀ   IÁ I^         device    channel 	           split    . 	      require    luci.model.network    init    get_wifidev 	      set    commit 	   wireless    save    hiwifi.net    get_wifi_bridge    delay_exec_wifi 	      delay_exec_ifwanup 	  	     get_api_error    code    msg                       ¶    H      A@     Ê   
  A    ÁÁ   ÆAÜ   @AÀ
FA\ WÀÁ@  BÀ À @FÄ B	ÆÄÆDÂ	 I!  ý ÃB@   WÀAC À C C  @BCÁ B C@ô @    D FÂÃ  \ @ É 		A 	Á      	           require    hiwifi.net    do_wifi_ctl_scan 	
      get_aplist     getn    ssid    fliter_unsafe    get_channel_rank 	      execute    sleep 1    get_api_error    rank    code    msg    data                             