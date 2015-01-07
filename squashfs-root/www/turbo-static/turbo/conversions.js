/*
* 单位转换
* Author: chaogang.liu@hiwifi.tw
*/
var conversions = {
    'traffic_format': function(val, target_unit){
        if(val){
            var a_val = val
            var a_val_num = parseFloat(a_val)
            if(!isNaN(a_val_num)){
                var unit_val = a_val.substr(a_val.length - 2, 2)
                var units = this.traffic_unit()
                var unit_data = units[unit_val]
                if(unit_data){
                    if(target_unit){
                        var target_unit_data = units[target_unit]
                        if(target_unit_data){
                            var kb_val = a_val_num * parseInt(unit_data.ratio) / parseInt(target_unit_data.ratio)
                            return {'value':kb_val, 'unit':target_unit_data.key}
                        }
                    }
                }
            }
        }
        return null
    },

    'traffic_unit': function(){
        return {
                'TB':{'key':'TB', ratio: 8000000000},
                'Tb':{'key':'Tb', ratio: 1000000000},
                'GB':{'key':'GB', ratio: 8000000},
                'Gb':{'key':'Gb', ratio: 1000000},
                'MB':{'key':'MB', ratio: 8000},
                'Mb':{'key':'Mb', ratio: 1000},
                'KB':{'key':'KB', ratio: 8},
                'Kb':{'key':'Kb', ratio: 1}
                }
    }
}
