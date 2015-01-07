var storage = {

	'format_size': function(a)
	{
		if(typeof(a) == "string" && a.length > 0){
            var a_val = a.toUpperCase();
            var unit = a_val.substr(a_val.length - 1, 1)
            var num = 0
            if(unit >= 0 && unit <= 9){
                num = a_val
            }else{
                num = a_val.substr(0, a_val.length - 1)
            }
            var n = 1;
            if(unit == 'T'){
                n = 1000*1000*1000;
            }else if(unit == 'G'){
                n = 1000*1000;
            }else if(unit == 'M'){
                n = 1000;
            }else if(unit == 'K'){
                n = 1;
            }
            var k_num = parseFloat(num) * parseInt(n);
            return k_num;
        }
        return false;
	},

    'compare_size': function(a, b)
	{
		var a_val = storage.format_size(a);
        var b_val = storage.format_size(b);
        if(a_val){
            if(b_val){
                if(a_val < b_val){
                    return -1;
                }else if(a_val == b_val){
                    return 0;
                }else{
                    return 1;
                }
            }else{
                return 1;
            }
        }else{
            if(b_val){
                return -1;
            }else{
                return 0;
            }
        }
	},
    // 单位换算 v: 容量 unit:新单位
    'conversion': function(v, unit)
	{
        if(typeof(v) == "string"){
            var val = storage.format_size(v);
            if(val){
                if(typeof(unit) == "string"){
                    var unit_tmp = unit.toUpperCase();
                    var n = 1;
                    if(unit_tmp == 'T'){
                        n = 1000*1000*1000;
                    }else if(unit_tmp == 'G'){
                        n = 1000*1000;
                    }else if(unit_tmp == 'M'){
                        n = 1000;
                    }else if(unit_tmp == 'K'){
                        n = 1;
                    }
                    var rst = ""                    
                    rst += val/parseFloat(n)
                    rst += unit_tmp
                    return rst;
                }
            }
        }
        return false;
	}
};

