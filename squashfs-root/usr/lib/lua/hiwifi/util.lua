LuaQ               >      E@    Εΐ   EA  \ A ΑΑ  ΕA  ά B AB  EB  \ B ΑΒ  Ε C άB δ                  $C           $           Γ $Γ       $   C $C            $          Γ         io    table    type    string    pairs    require    hiwifi.digest    ltn12 	   nixio.fs    socket.http 
   ssl.https    tw    module    hiwifi.util    download_to_string    download_to_file #   download_to_file_with_md5_checking    is_ssl    https_curl_post    request_body_to_string           )    
:      ΐ     @ @      	@ @  Α   AA Υ ΐΔ  A A      ά  ΒA@  ΐα   ώ	 Ε  A@ ά Ϊ   ΐΖ@B Ϊ@    Α 	ΐΖΐB Ϊ@    Α  	ΐΔ  Ζ@Γ   έ  ή    Δ Ζ@Γ   έ  ή           string    url    sink    user-agent    HiwifiLuaLib-    get_mac    headers    lower    is_ssl    verify    peer    capath    /etc/ca    request                     1   6       J       @@@ΐ   Δ     @ άΐD Fΐ \ ΐ ^         sink    table    concat                     @   D           @@@Δ  Ζΐ  AΑ  ά   Δ     @ άΐ         sink    file    open    w                     M   U       Ε      @ ά  A@@  W ΐD Fΐ \A B  ΐ ^ B ^         download_to_file    md5file    remove                     Z   `       D   F ΐ    Α@    \ ΐΐ  B  ^  @ B   ^          sub 	   	      https                     h       A   Z@  @    @     Κ     ΐ  @@   ΐ    @  ΐ  ΐ@     ΐ   A  @ @  AΚA ΙΙAB
  D FΓ \ 	B	ΓΙΒCΒ@@  ΙDB@@ ΙA FAΔAΔA     ΐ      	       table    request_body_to_string    string    is_ssl 	!     request    url    method    POST    headers    Content-Length    len    Content-Type "   application/x-www-form-urlencoded    source    sink 	   	"                                A      Δ      ά @ΐΐΔ     ά ΐ @@  ΑΒ   Bα  @ύΔ  Ζ Α  AA ά@ ^              table    insert    =    concat    &                             