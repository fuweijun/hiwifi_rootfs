LuaQ               ?      A@   A  ΐ  Α  A A Α Α   AB  E   \   ΑΒ  Ε   ά   AC  E   \   ΑΓ  Α   AD  FDΔ U Ε  E ά  E Ε Ε ΖEΖ\Ed  G dE  GΕ d  G dΕ  GE d G dE   	   
GΕ          require    hiwifi.json    /tmp/upgrade_firmware_info.txt    /tmp/clinet_token    /tmp/upgrade_firmware_md5    /tmp/firmware.img    /etc/config/led_disable !   /etc/config/remote_script_enable    pejlwcc4lfak    luci.fs    socket.http    ltn12    luci.http.protocol    tw    hiwifi.firmware    hiwifi.conf    /etc/nginx/mode    luci.cbi.datatypes    firmware_path    /    rom.bin    openapi.utils.utils    module    openapi.system.os    package    seeall    reboot 
   reset_all 	   get_info    set_password    nbrinfo    set_systime           *      
   
   E   F@ΐ   \@ 	 Α	Α	Α          os    execute    /usr/sbin/hwf-at 5 reboot    code    0    msg        data                     /   =      
   
   E   F@ΐ   \@ 	 Α	Α	 Β    	      os    execute N   /usr/sbin/hwf-at 5 '/sbin/firstboot && /sbin/reboot & >/dev/null 2>/dev/null'    code    0    msg    reset success    data                         B   o      A      A@   E     \ ΐ  Α  A J   Κ   ΒABAB  A W A@ B@    Α Γ ΐ    ΐ AΒ BΓ ΐ B  Α@ΒC  I ΒABD IΒD  EC IIΑBIIA@ ΒABFΐ   ΙAΙΑΙή         require    tw 	   nixio.fs    /etc/app/no_auto_bind 	           luci    util    get_agreement    HAVESETSAFE    0 	      access    remove    mac    get_mac 
   sys_board    get_sys_board    version    get_version    match 
   ^([^%s]+)    support_client_bind 
   issetsafe 
   auto_bind    get_api_error    data    code    msg                     u        =   F @ @@ Ε  Α  ά  AAAΑAA  W@Β @E FΒFΑΒ \ @ A A Κ   J  W@Β @ @Γ @ A  A  @ AΑ  Δ  X@Dΐ Δ  @ AΑ  BAAEΑ     W C  AA IΒIBI^      	   password    old_password    require 	   luci.sys    luci    sys    user    checkpasswd    root     util    trim 	        	-  	.     len 	   	@   	/  
   setpasswd 	θ     data    code    msg                     ‘   Ϋ      ]     AB    Κ    AΓ   E FCΑFΑ\Γ ΕΔ  EA
B
AE  E  ΐ EA
B
A  E    E  ΕB
 ά  ΪD    Α  Ε E FEΑ
FΒ
E \ ZE  ΐE FEΑ
FΒ
 \ ZE    AE  KΕΒ
Α \  E    Ε   @   ΐ   	@ 
	J  D bE  ΐ
 @B Β BJ  BΒ@E FΖ
FEΖ
 \ @
ΙΙΙBή      	           require 	   luci.sys    luci    sys    sysinfo 	   tonumber    exec    wc -l /proc/net/nf_conntrack    wc -l /proc/net/ip_conntrack    match    %d+    sysctl net.nf_conntrack_max +   sysctl net.ipv4.netfilter.ip_conntrack_max 	      loadavg    system 	   memtotal 
   memcached    membuffers    memfree 	   conn_max    conn_count    util    get_api_error    data    code    msg                     έ         D   F ΐ   Ε@  \@F@@ ΐ    ΐ@Α  A A      ΐ  Bΐ   W@B   ΐ@Α   A      ΐ Εΐ Ζ Γ  AA  ά    Εΐ Α C@ Α Α  ά  Α EΑ FΓ ΑA  \   EΑ Α Cΐ Β A  \  Α ΕΑ ΖΓ  AB  ά   ΕΑ Β C@ Β ΑB  ά     Ϊ      Z      Ϊ      Β@A  Α     @@Fΐΐ @ΐΕΐ @ΐFΐ@@ Ηΐ@@Gΐ ΐ@ X@Η  Β@A Β Α     BHHAΒ  Α	  A	  ΑC	  A	  Α	  AΕ	 UBB   Β@A
 B
 Α      *      debug    date     ret_output    1    date is nil        string    len 	      date is illegal 	   tonumber    sub 	   	   	   	   	   	   		   	
   	   	   	   	²  	Έ  	    	    	   	<      2    date is out of range    luci    util    execi 
   date -s '    -         :    '    0    set_systime success                             