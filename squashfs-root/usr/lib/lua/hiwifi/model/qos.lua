LuaQ               y      @   @  \   ÅÀ   EA  ÅÁ  @  B \  ÁÂ B  ÁB   A ÕBC @ Ã A ¤     äC     $        dÄ     ¤        D ¤D             ¤             Ä ¤Ä                 ¤           D ¤D            ¤           Ä ¤Ä            ¤           D ¤D            ¤             Ä ¤Ä              ¤        D ¤D         ¤   Ä ¤Ä    ¤      D   "      require 
   luci.util    os    string 	   tonumber    table    type    math    pcall    hiwifi.model.logger    module    hiwifi.model.qos    /usr/sbin/twx/qos_adapter.sh 	   (source      && start_speed_test)     && speed_test_result) 	@      start_speed_test    speed_test_result    status    set_total_qos    start    stop    restart    disable    enable    set_device    unset_device_config    get_device_config_list    get_traffic_list    reload    get_max_device    get_used_device    reload_retry               
   D      \ Z   @  À            	                              
   D      \ Z   @  À            	                                    ÀD      \  À D  @@ \ À @ B  ^  B   ^          table    code 	                            %          @D      \  À  F@@ Z   @ F@@ ^  C  ^          table    data                     &   /            @ D   J         @@À        I¡   ÿ^          exec    gmatch    (%w+)=(%C+)                     0   9     !   
   D   F À @  Ä     \     @Á@   AÁ  Õ@ Ä    Ü 	À Ä    Ü 	ÀÄ   Ü 	À Ä   Ü 	À          exec 	   (source      && speed_test_up)     && speed_test_down) 	   speed_up    speed_down    speed_up_kb    speed_down_kb                     :   d     2   
   J   ¤             Ä    Ü@ Ê   À FAÀ @ ÆA@   D \ @D  \  D\ ÀD \ dB         ÀB É@É ÉÀÉÉ   É  ÉÞ          down    up 	   total_up    total_down    total_up_kb    total_down_kb    active    max_device    get_max_device    used_device    get_used_device        =   D           A    F@@ \ Z   À    ÀÀ À@@         À  A@                 openapi.network.sqosutils    get_bandwidth    data    saved 	   deployed                     P   Z           A    F@@ \ Z   ÀÀ     À À@ A     @              openapi.network.sqosutils    status    data    state    enable                                 e   {    ;   F @ @@ Ä     Ü @ Ä     Ü     
Z    
Ä    Ü  Ä  ÆÀ  Ü  Ä    Ü @ Ä  ÆÀ  Ü @ Ã $     D  Ê  ÉA É\Z  @Ú   ÀD  ÁÀ\  Á JA  IÁ^ ã   Ê@  É@ÁÞ          down    up    ceil    code 	    	          p   s       D      \ @À À              openapi.network.sqosutils    set_bandwidth                                 |           d            À  @    À  Æ @  @@ @  @@  @  @          code 	    	          ~              A    F@@ \ H          openapi.network.sqosutils    start                                            d            À  @    À  Æ @  @@ @  @@  @  @          code 	    	                        A    F@@ \ H          openapi.network.sqosutils    stop                                            d            À  @    À  Æ @  @@ @  @@  @  @          code 	    	                        A    F@@ \ H          openapi.network.sqosutils    restart                                     «        d            À  @    À  Æ @  @@ @  @@  @  @          code 	    	          ¢   ¥           A    F@@ \ H          openapi.network.sqosutils    disable                                 ¬   ·        d            À  @    À  Æ @  @@ @  @@  @  @          code 	    	          ®   ±           A    F@@ \ H          openapi.network.sqosutils    enable                                 ¸   ×    9      @ @ B@ A     Â@ Û@   Á  A A     BA [A   A  ÆA $        D  Ê É ÉÂÉÉBÉÉÂ\BZ   @D ÂÁ \  ÂÀ JB  IÂ^  EB \   X JB  IÂÂ^ JB  IÀ^         mac    down 	ÿÿÿÿ   up    downg    upg    name    code 	       get_used_device    get_max_device 	          È   Ë       D      \ @À À              openapi.network.sqosutils    set_device_config                                 Ø   æ       d         Ä    @  ÜÀÚ    D  \ Z  ÀD \ @@ J   Àÿ               Ù   Ü       D      \ @À À                openapi.network.sqosutils    unset_device_config                                 ç   ö        $      J     À   À      @   À@ [@ @ 
  @  Àÿ^               è   ì           A    F@@ \ ^          openapi.network.sqosutils    get_device_config_list                                 ÷          $      J     À   À     ÀI AÀI Àÿ^          total    list        ø   ÿ           A    F@@ \ Z    À    @ À                openapi.network.sqosutils    get_traffic_list    data                                 	         $      C    À   À    @ @ Àÿ^               
            A    F@@ ]  ^           openapi.network.sqosutils    reload                                                                                      D   F@À    ]  ^           get_device_config_list    getn                       '    	      A@     Á@  `@D  FÀÁ  Á   Õ\AEA   \ ÁÀA  ^  BÁA A _ û  
   	   	      syslog    info &   twx: call sqosutils.reload(), times:     reload    code 	       execute    sleep 2                             