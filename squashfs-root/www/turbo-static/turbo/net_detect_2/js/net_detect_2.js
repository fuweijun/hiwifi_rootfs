function type_defined(obj){
    return typeof(obj) != "undefined";
}

function json_to_string(rsp){
    try{
        return JSON.stringify(rsp);
    }catch(e){
        return "";
    }
}

function replacelastchar(msg, from, to){
    if(type_defined(msg) && msg.length > 1 && msg.charAt(msg.length - 1) == from){
        return msg.substring(0, msg.length - 1) + to;
    }else{
        return msg;
    }
}

function append_msg(msg, new_msg, link_tag){
  var link = "";
  if(link_tag && typeof(link_tag) != "undefined"){
     link = link_tag;
  }
  var a1 = "";
  var a2 = "";
  if(msg && typeof(msg) != "undefined" && msg.length > 0){
    a1 = msg;
  }
  if(new_msg && typeof(new_msg) != "undefined" && new_msg.length > 0){
    a2 = new_msg;
  }
  if(a1 == "" || a2 == ""){
    return a1 + a2;
  }
  return a1 + link + a2;
}

function set_wifi_type(wifi_type_value){
    if(typeof(wifi_type_value) == "undefined"){
        wifi_type = "";
    }else{
        wifi_type = wifi_type_value;
    }
}

function get_wifi_type(){
    return wifi_type;
}

function check_ip(obj){
    //ip地址
    var exp=/^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])$/;
    var reg = obj.match(exp);
    if(reg==null){
        return false;
    }else{
        return true;
    }
}

function is_link_success(state){
  return state == 1 || state == '1';
}

// 路由器到设备
function update_hiwifi_dev_view(){
    test_txpwr();
    channel_get_then_check();
}

//1.2
function test_txpwr(){
    //wifi/get_txpwr 
    var request_data = {"device":"radio0.network1"}; 
    $.getJSON(find_api_url("api", "wifi","get_txpwr"),request_data,function(rsp) 
    {
        var rst = 'ERROR';
        var msg = '';
        if(rsp.code == 0){
            if(type_defined(txpwr_s[rsp.txpwr])){
                if(rsp.txpwr == 'min' || rsp.txpwr == 'mid'){
                    rst = 'NORMAL';
                    msg = find_test_result_msg("txpwr_weak", {'txpwr':rsp.txpwr})
                }else{
                    rst = 'SUCCESS';
                }
            }else{
                rst = 'NORMAL';
                msg = find_test_result_msg("txpwr_faild")
            }
        }else{
            rst = 'ERROR';
        }
        hiwifi_dev_result_s.push({'item':'txpwr','rst':rst, 'msg':msg});
        show_test_result({'group':'dev_router', 'item':'txpwr','rst':rst, 'msg':msg})
        update_hiwifi_dev_alert();
    })
    .fail(function(rsp){
        var rst = 'ERROR';
        var msg = find_test_result_msg("txpwr_error")
        hiwifi_dev_result_s.push({'item':'txpwr','rst':rst, 'msg':msg});
        show_test_result({'group':'dev_router', 'item':'txpwr','rst':rst, 'msg':msg})
        update_hiwifi_dev_alert();
    });
}

//1.3
function channel_get_then_check(){
    if(wifi_status == '0'){
        var rst = 'NORMAL'
        var msg = find_test_result_msg("wifi_closed")
        hiwifi_dev_result_s.push({'item':'channel','rst':rst, 'msg':msg});
        show_test_result({'group':'dev_router', 'item':'wifi_closed','rst':rst, 'msg':msg})
        update_hiwifi_dev_alert();
        return;
    }
    if(get_wifi_type() == null){
        setTimeout("channel_get_then_check()", 1000);
        return;
    }else if(get_wifi_type() == "5G"){
        need_check_channel = false;
    }
    if(!type_defined(need_check_channel)){
        setTimeout("channel_get_then_check()", 1000);
        return;
    }else if(need_check_channel == false){
        hiwifi_dev_result_s.push({'item':'channel','rst':'SUCCESS', 'msg':''});
        update_hiwifi_dev_alert();
        return;
    }
    if(!type_defined(wifi_channel)){
        return;
    }
    if(wifi_channel > 0){
        check_channel(wifi_channel);
    }else{
        //wifi/get_channel 
        var request_date = {"device":"radio0.network1"}; 
        $.getJSON(find_api_url("api", "wifi","get_channel"),request_date,function(rsp) 
        {
            if(rsp.code == 0){ 
                //auto fill--  
                var channel_real = rsp.channel;
                if(rsp.channel == "" || rsp.channel == "0"){
                    channel_real = rsp.channel_autoreal;
                }
                check_channel(channel_real);
            }else{
                
            }
        })
        .fail(function(rsp){
            var rst = 'ERROR';
            var msg = find_test_result_msg("channel")
            hiwifi_dev_result_s.push({'item':'channel','rst':rst, 'msg':msg});
            show_test_result({'group':'dev_router', 'item':'channel','rst':rst, 'msg':msg})
            update_hiwifi_dev_alert();
        });
    }
}

function is_channel_rank(ranks, index){
    var is_rank = false;
    try{
        if(type_defined(ranks) && type_defined(ranks[index]) && ranks[index] >= 0 && ranks[index] <= 1){
            is_rank = true;
        }
    }catch(e){
    }
    return is_rank;
}

function check_channel(now_channel){
    //wifi/get_channel 
    var request_date = {}; 
    $.getJSON(find_api_url("api", "wifi","get_channel_rank"),request_date,function(rsp) 
    {
        var rst = 'ERROR';
        var msg = '';
        if(rsp.code == 0){
            if(typeof(rsp.rank) != "undefined"){
                if(typeof(rsp.rank.length) == "undefined" || rsp.rank.length == 0){
                    rst = 'SUCCESS';
                }else{
                    var channel_index = now_channel - 1;
                    if(is_channel_rank(rsp.rank, channel_index)){
                        if(rsp.rank[channel_index] <= 0.5){
                            rst = 'SUCCESS';
                        }else{
                            var recommend_channel = '0';
                            var recommend_channel_rank = '1';
                            $.each(rsp.rank, function( index, value ) {
                                if(index < 11){
                                    if(recommend_channel_rank > value){
                                       recommend_channel_rank = value;
                                       recommend_channel = index + 1;
                                    }
                                }
                            });
                            rst = 'NORMAL';
                            msg = find_test_result_msg("channel_crowded", {'recommend_channel':recommend_channel})
                        }
                    }else{
                       rst = 'NORMAL'; 
                       msg = find_test_result_msg("channel")
                    }
                }
            }else{
                rst = 'SUCCESS';
            }
        }else{
            rst = 'NORMAL'; 
            msg = find_test_result_msg("channel")
        }
        hiwifi_dev_result_s.push({'item':'channel','rst':rst, 'msg':msg});
        show_test_result({'group':'dev_router', 'item':'channel','rst':rst, 'msg':msg})
        update_hiwifi_dev_alert();
    })
    .fail(function(rsp){
        var rst = 'ERROR';
        var msg = find_test_result_msg("channel")
        hiwifi_dev_result_s.push({'item':'channel','rst':rst, 'msg':msg});
        show_test_result({'group':'dev_router', 'item':'channel','rst':rst, 'msg':msg})
        update_hiwifi_dev_alert();
    });
}

//设备到路由器测试组
function update_dev_hiwifi_alert(){
    if(dev_hiwifi_result_s.length == 2){
        var test_size = dev_hiwifi_result_s.length;
        var error = 0;
        var normal = 0;
        var success = 0;
        var msg = '';
        $.each(dev_hiwifi_result_s, function(index, value ) {
            if(value.rst == 'ERROR'){
                error++;
            }else if(value.rst == 'NORMAL'){
                normal++;
            }else if(value.rst == 'SUCCESS'){
                success++;
            }
            if(typeof(value.msg) != "undefined" && value.msg.length > 0){
                msg += value.msg + '；';
            }
        });
        msg = replacelastchar(msg, '；', "。");
        
        var success_pencent = success / test_size;
        var state_result = false;
        if(success_pencent == 1 || success_pencent == '1'){
            state_result = true;
        }else if(success_pencent == 0 || success_pencent == '0'){
            state_result = false;
        }else{
            state_result = false;
        }
        update_info_box_show('pop-state1', state_result);
    }
}

// 设备到路由器
function update_dev_hiwifi_view(){
    dev_hiwifi_result_s = new Array();
    test_device_signal(function(rst, msg){
        dev_hiwifi_result_s.push({'item':'device_signal','rst':rst, 'msg':msg});
        show_test_result({'group':'dev_router', 'item':'device_signal','rst':rst, 'msg':msg})
        update_dev_hiwifi_alert();
    });
    
    test_dev_hiwifi_http_get(function(rst, msg){
        dev_hiwifi_result_s.push({'item':'dev_hiwifi_http_get','rst':rst, 'msg':msg});
        show_test_result({'group':'dev_router', 'item':'dev_hiwifi_http_get','rst':rst, 'msg':msg})
        update_dev_hiwifi_alert();
    });
}

//2.1
function test_device_signal(callback){
    var request_data = {'mac':mac_local}; 
    var device_signal = false;
    $.getJSON(find_api_url("api", "network","device_signal"),request_data,function(rsp) 
    { 
        var msg = rsp.msg;
        var rst = 'ERROR';
        if(rsp.code != 0 || rsp.code != '0'){
            // mac 错误时忽略
            if(rsp.code == 521 || rsp.code == '521'){
                rst = 'SUCCESS';
            }else{
                rst = 'ERROR';
            }
        }else{
            if(rsp.type == 'wifi'){
              if(rsp.signal > 60){
                 device_signal = true;
              }else if(rsp.signal > 30){
                 device_signal = true;
              }else{
                device_signal = false;
              }
            }else if(rsp.type == 'line'){
                device_signal = true;
            }
            update_dev_type_view();
            if(device_signal == true){
                rst = 'SUCCESS';
            }else{
                rst = 'ERROR';
                msg = find_test_result_msg("device_signal_weak")
            }
        }
        if(type_defined(callback)){
            callback(rst, msg);
        }
        set_wifi_type(rsp.wifi_type);
    })
    .fail(function(rsp){
        var rst = 'ERROR';
        var msg = find_test_result_msg("http_fail", {'item':'device_signal'})
        if(type_defined(callback)){
            callback(rst, msg);
        }
    });
}

//2.2
function test_net_detect_ping_remote(callback){
    var request_data = {};
    $.getJSON(find_api_url("api", "network","net_detect_ping_remote"),request_data,function(rsp) 
    { 
        var msg = rsp.msg;
        var rst = 'ERROR';
        if(rsp.code != 0 || rsp.code != '0'){
            rst = 'ERROR';
        }else{
            if(rsp.loss == 0 && rsp.min <= 100){
               rst = 'SUCCESS';
            }else{
               rst = 'NORMAL';
               msg = find_test_result_msg("net_detect_ping_remote_loss")
            }
        }
        if(type_defined(callback)){
            callback(rst, msg);
        }
    })
    .fail(function(rsp){
        var rst = 'ERROR';
        var msg = find_test_result_msg("http_fail", {'item':'net_detect_ping_remote'})
        if(type_defined(callback)){
            callback(rst, msg);
        }
    });
}

//2.3
function test_dev_hiwifi_http_get(callback){
    $("#test_host_img")
    .error(function() {
        var rst = 'ERROR';
        var msg = find_test_result_msg("device_dns")
        if(type_defined(callback)){
            callback(rst, msg);
        }
    })
    .load(function() {
        var rst = 'SUCCESS';
        var msg = '';
        if(type_defined(callback)){
            callback(rst, msg);
        }
    })
    .attr("src", "http://hiwifi.com/turbo-static/turbo/web/images/logo_130726.png");
}

function get_dev_type(){
    var userAgentInfo=navigator.userAgent.toLocaleLowerCase();
    var mobileKeywords=new Array("Android", "iPhone" ,"SymbianOS", "Windows Phone", "iPod", "MQQBrowser");
    var padKeywords=new Array("iPad", "pad");
    
    var i = 0;
    for (i = 0; i < mobileKeywords.length; i++)
    {
        if(userAgentInfo.match(mobileKeywords[i].toLocaleLowerCase())) {
            return 'phone';
        }
    }
    
    i = 0;
    for (i = 0; i < padKeywords.length; i++)
    {
        if(userAgentInfo.match(padKeywords[i].toLocaleLowerCase())) {
            return 'pad';
        }
    }
    
    return 'pc';
}

function update_dev_type_view(){
  var dev_type = get_dev_type();
  var dev_type_class = ""
  var dev_name = ""
  if(dev_type == 'phone'){
    dev_type_class = "phone"
    dev_name = "我的手机"
  }else if(dev_type == 'pad'){
    dev_type_class = "pad"
    dev_name = "我的平板"
  }else if(dev_type == 'pc'){
    dev_type_class = "pc"
    dev_name = "我的电脑"
  }else{
    dev_type_class = "pc"
    dev_name = "我的电脑"
  }
  $("#mydevpic").removeClass("phone pad pc");
  $("#mydevpic").addClass(dev_type_class);
  $("#mydevname").text(dev_name);
}

function show_inet_chk_switch(){
    var request_data = {};
    $.getJSON(find_api_url("api", "network","get_inet_chk_state"),request_data,function(rsp) 
    { 
        var msg = rsp.msg;
        var code = rsp.code;
        var state = rsp.state;
        if(code == 0 || code == "0"){
            if (state == "on"){
                inet_chk_state = "on";
                $('.J_switch').addClass('on').removeClass('off');
                $("#switch_btn_span").show();
            }else if(state == "off"){
                inet_chk_state = "off";
                $('.J_switch').addClass('off').removeClass('on');
                $("#switch_btn_span").show();
            }else{
                
            }           
        }else{
        }
    })
    .fail(function(rsp){
    });
}

function inet_chk_switch(){
    var request_data = null;
    if(inet_chk_state == "on"){
       request_data = {"cmd":"off", "timeout":168};
    }else if(inet_chk_state == "off"){
       request_data = {"cmd":"on"};
    }
    if(request_data != null){
        $.getJSON(find_api_url("api", "network","inet_chk_switch"),request_data,function(rsp) 
        { 
            var msg = rsp.msg;
            var code = rsp.code;
            var state = rsp.state;
            if(code == 0 || code == "0"){
                inet_chk_state = request_data.cmd;
            }else{
               if(code == "99999"){
                alert("需要登录后才能修改");
               }
            }
            show_inet_chk_switch();
        })
        .fail(function(rsp){
            show_inet_chk_switch();
        });
    }
}

// 设备到运营商
function update_hiwifi_icp_show(){
    var request_data = {};
    if(iscont == 1){
      request_data = {'dnotcheckwan':1}; 
    }
    $.getJSON(find_api_url("api", "network","net_detect_1"), request_data, function(rsp) 
    {
        do_detect_show(rsp.is_eth_link, rsp.isconn, rsp.isnetok, rsp.uciwantype, rsp.autowantype, rsp.dns, rsp.peerdns, rsp.max_up, rsp.max_down, rsp.override_dns, rsp.override_dns2);
    })
    .fail(function(rsp){
        var rst = 'ERROR'
        var msg = find_test_result_msg("http_fail", {'item':'net_detect_1'})
        show_test_result({'group':'router_icp', 'item':'net_detect','rst':rst, 'msg':msg})
    });
}

function do_detect_show(is_eth_link, isconn, isnetok, uciwantype, autowantype, dns, peerdns, max_up, max_down, override_dns, override_dns2){
    var error_title = '';
    var error_info = '';
    var has_error = false;
    var dns_buf = '';
    var link_buf = '';
    var peerdns_buf = '';
    var up_down_buf = '';
    var err_count = 0;
    var link = false;
    var eth_link_buf = '';
    
    if(is_link_success(is_eth_link)){
        if(isconn == 1 || isconn == '1'){
            if(isnetok == true || isnetok == 'true' || isnetok == 1 || isnetok == '1'){
                link = true;
            }else{
                link = false;
                link_buf = find_test_result_msg('no_con_'+uciwantype)
                err_count ++;
                show_test_result({'group':'router_icp', 'item':'no_con_'+uciwantype,'rst':'ERROR', 'msg':link_buf})
            }
        }else{
            if(uciwantype == 'pppoe'){
                update_ppp_status_view();
            }else{
                link_buf = find_test_result_msg('no_con_'+uciwantype)
                show_test_result({'group':'router_icp', 'item':'no_con_'+uciwantype,'rst':'ERROR', 'msg':link_buf})
            }
            err_count ++;
        }
    }else{
        eth_link_buf = find_test_result_msg('unlink_'+uciwantype)
        err_count ++;
        show_test_result({'group':'router_icp', 'item':'unlink_'+uciwantype,'rst':'ERROR', 'msg':eth_link_buf})
    }
    
    if(dns.length == 0){
        dns_buf = find_test_result_msg('net_detect_dns_miss')
        err_count ++;
        show_test_result({'group':'router_icp', 'item':'net_detect_dns_miss','rst':'ERROR', 'msg':dns_buf})
    }
        
    if (autowantype) {
      if(uciwantype_s[uciwantype] != autowantype_s[autowantype]){
          link_buf = find_test_result_msg("uciwantype_not_eq_autowantype", {'item':'net_detect'})
          err_count ++;
          show_test_result({'group':'router_icp', 'item':'net_detect','rst':'ERROR', 'msg':link_buf})
      }
    }
    
    //自定义了dns
    if(peerdns == 0 || peerdns == '0'){
        peerdns_buf = find_test_result_msg("net_detect_dns", {'item':'net_detect_dns'})
        err_count ++;
        show_test_result({'group':'router_icp', 'item':'net_detect_dns','rst':'ERROR', 'msg':peerdns_buf})
        if(type_defined(override_dns) && check_ip(override_dns)){
            dns_buf += override_dns;
            if(type_defined(override_dns2) && check_ip(override_dns2)){
                dns_buf += '/' + override_dns2;
            }
        }
    }
    
    //宽带占用
    if(max_down > limit_down_speed){
        up_down_buf = find_test_result_msg("devices_down_speed", {'item':'devices_down_speed', 'max_down':max_down})
        err_count ++;
        show_test_result({'group':'router_icp', 'item':'devices_down_speed','rst':'NORMAL', 'msg':up_down_buf})
    }
    
    if(!is_link_success(is_eth_link)){
        error_info = append_msg(error_info, eth_link_buf, "<br/>");
    }
    error_info = append_msg(error_info, link_buf, "<br/>");
    if(peerdns == 0 || peerdns == '0'){
        error_info = append_msg(error_info, peerdns_buf, "<br/>");
    }
    error_info = append_msg(error_info, up_down_buf, "<br/>");
    
    /*
    if(uciwantype == 'wisp'){
        need_check_channel = false;
    }else{
        need_check_channel = true;
    }
    */
    
    if(err_count > 0){
        var rst
        if(err_count / 4 == 1 || link != true){
            rst = 'ERROR'
        }else{
            rst = 'NORMAL'
        }
        update_info_box_show('pop-state2', false);
    }else{
        update_info_box_show('pop-state2', true);
    }
}

function get_ppp_errorcode_by_msg(msg){
    var code = 0
    var str = msg;

    var ch = new Array;
    var chu =  new Array;
    ch = str.split(" ");

    if (ch.length > 0){
        chu = ch[0].split("E=");
        if (chu.length>0){
            code = chu[1];
        }
    }
    return code
}

function get_ppp_error_msg(code){
    if (error_list[code]){
        return error_list[code];
    }
    return "";
}

function update_ppp_status_view(){
    //network/get_pppoe_status 
    $.ajax({
          url: find_api_url("api", "network","get_pppoe_status"),
          cache: false,
          dataType: "json",
          success: function(rsp){
                var has_check_pppoe_status = false;
                var ppp_msg = "";
                var success = false;
                var ppp_err_code = ""
                if(rsp.code == 0){
                    var special_msg = "";
                    var special_num;
                    special_num = parseInt(rsp.special_dial_num)+1;
                    if (rsp.special_dial == "1"){
                        special_msg = "正在尝试拨号 "+special_num+"/8 ";
                    }
                    
                    if(rsp.remote_message){
                        ppp_err_code = get_ppp_errorcode_by_msg(rsp.remote_message)
                    }
                    
                    if (rsp.status_code == -1){
                        ppp_msg = get_ppp_error_msg(rsp.status_code);
                        if(get_ppp_errorcode_by_msg(rsp.remote_message)){
                             ppp_msg = get_ppp_error_msg(get_ppp_errorcode_by_msg(rsp.remote_message));
                        };
                    } else if (rsp.status_code == 0) {
                       success = true;
                    } else {
                        if(rsp.status_code == 9999){
                            ppp_msg = "WAN 未连接网线或宽带拨号断开，请检查WAN口网线和宽带帐号密码是否有效。";
                        } else {
                           // var error_msg = "错误  "+rsp.status_code+" "+rsp.status_msg ;
                            ppp_msg = get_ppp_error_msg(get_ppp_errorcode_by_msg(rsp.remote_message));
                        }
                        
                        if (rsp.remote_message){
                            ppp_msg = get_ppp_error_msg(get_ppp_errorcode_by_msg(rsp.remote_message));
                        }
                    }
                }
                
                if(!success){
                  update_info_box_show('pop-state2', false);
                  var item = "pppoe"
                  if(ppp_err_code && ppp_err_code.length > 0){
                    item = item + "_" + ppp_err_code
                  }else{
                    var status_code = rsp.status_code
                    if(status_code && status_code == -1){
                        item = item + "_pending"
                    }
                  }
                  show_test_result({'group':'router_icp', 'item':item,'rst':'ERROR', 'msg':ppp_msg})
                }
        },error :function(rsp){
        }
    });
}

function update_hiwifi_dev_alert(){
    if(hiwifi_dev_result_s.length == 2){
        var test_size = hiwifi_dev_result_s.length;
        var error = 0;
        var normal = 0;
        var success = 0;
        var msg = '';
        $.each(hiwifi_dev_result_s, function(index, value ) {
            if(value.rst == 'ERROR'){
                error++;
            }else if(value.rst == 'NORMAL'){
                normal++;
            }else if(value.rst == 'SUCCESS'){
                success++;
            }
        });
        var success_pencent = success / test_size;
        var state_result = false;
        if(success_pencent == 1 || success_pencent == '1'){
            state_result = true;
        }else if(success_pencent == 0 || success_pencent == '0'){
            state_result = false;
        }else{
            state_result = false;
        }
        update_info_box_show('pop-state4', state_result);
    }
}

function test_dev_web(){
    try{
        var baidu_img = new Image();
        $(baidu_img).error(function() {
        })
        .load(function() {
        })
        .attr("src", "http://www.baidu.com/img/bdlogo.gif");
    }catch(e){}
}

// 4.1 4.2 test 互联网
function check_website_140523(){
    check_website_url_result_s = new Array();
    var site_size = check_website_url_s.length;
    var complete_size = 0;
    $.each(check_website_url_s, function(index, value){
        var url = value;
        var request_data = {'host':url};
        $.ajax({
          url: find_api_url("api", "net_detect","net_detect_host"),
          cache: false,
          dataType: "json",
          data: request_data,
          timeout: 20000,
          success: function(rsp){
            var pass = false;
            if(rsp.host == url && rsp.http == true){
                pass = true;
            }
            check_website_url_result_s[index] = pass;
            complete_size ++;
            if(complete_size == site_size){
                update_check_website_view();
            }
            if(!pass){
                var rst = 'ERROR'
                var msg = check_website_url_s[index] + ' 访问异常';
                show_test_result({'group':'icp_www', 'item':'check_website','rst':rst, 'msg':msg})
            }
          },
          error :function(jqXHR, textStatus, errorThrown){
            var rst = 'ERROR'
            var msg = check_website_url_s[index] + ' 访问异常';
            show_test_result({'group':'icp_www', 'item':'check_website','rst':rst, 'msg':msg})
            check_website_url_result_s[index] = false;
            complete_size ++;
            if(complete_size == site_size){
                update_check_website_view();
            }
          }
        });
    });
}

function update_check_website_view(){
    if(check_website_url_result_s.length == check_website_url_s.length){
        var errnum = 0;
        var set_num = 0;
        var err_url_buf = '';
        $.each(check_website_url_result_s, function(index, value){
            if(value == false){
                errnum ++;
                set_num ++;
            }else if(value == true){
                set_num ++;
            }
        });
        if(set_num != check_website_url_s.length){
            return;
        }
        if(errnum > 0){
            update_info_box_show('pop-state3', false);
        }else{
            update_info_box_show('pop-state3', true);
        }
    }
}
