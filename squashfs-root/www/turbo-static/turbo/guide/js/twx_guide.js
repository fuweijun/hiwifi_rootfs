function listerenterkeydown(down){
    document.onkeydown = function(e){     
        var ev = document.all ? window.event : e;    
        if(ev.keyCode==13) {  
            down();
            return false;
        }
    }
}

function twx_get_json(url, request_data, callback){
    $.getJSON(url,request_data,function(rsp) 
    {
        if(callback && typeof(callback.success) == "function"){
            callback.success(rsp);
        }
    }).fail(function(){
        if(callback && typeof(callback.error) == "function"){
            callback.error();
        }
    })
}

function twx_ajax(url, request_data, callback, timeout){
    var tmp_timeout = 60;
    var tmp_data = {};
    if(timeout){
        var tot = parseInt(timeout);
        if(tot > 0){
            tmp_timeout = tot;
        }
    }
    if(request_data){
        tmp_data = request_data;
    }
    $.ajax({
        url: url,
        cache: false,
        dataType: "json",
        data: request_data,
        timeout: tmp_timeout,
        success: function(rsp){
            if(callback && typeof(callback.success) == "function"){
                callback.success(rsp);
            }
        },error:function(){
            if(callback && typeof(callback.error) == "function"){
                callback.error();
            }
        }
    });
}

function twx_test_host(host, success_callback, error_callback, timeout){
    twx_ajax('/cgi-bin/turbo/api/net_detect/net_detect_host',
    {"host":host},
    {success: function(rsp){
        if(rsp.http == true){
            success_callback();
        }else{
            error_callback();
        }
    },
    error: function(){
        error_callback();
    }}, timeout);
}

function test_baidu(success_callback, error_callback, timeout){
    var tmp_timeout = 5000;
    if(timeout && parseInt(timeout) > 0){
        tmp_timeout = parseInt(timeout)
    }
    twx_test_host('www.baidu.com',
    function(){
        success_callback();
    },
    function(){
        error_callback();
    }, tmp_timeout);
}

function twx_timer(second, callback){
    var time = 1000;
    var tmp_sec = parseInt(second);
    if(tmp_sec >= 0){
        if(typeof(callback) == "function"){
            callback(tmp_sec);
        }
    }else{
        return;
    }
    var interval = window.setInterval(function() {
        tmp_sec = tmp_sec - 1;
        if(tmp_sec < 0){
            window.clearInterval(interval);
            return;
        }else{
            if(typeof(callback) == "function"){
                var rst = callback(tmp_sec);
                if(rst == false){
                    window.clearInterval(interval);
                    return;
                }
            }
        }
    }, time);
}