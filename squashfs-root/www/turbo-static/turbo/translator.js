var translator = {
	'translate': function(key, lang)
	{
		var dict = {'zh_cn':{'SD':'SD卡', 'DISK':'硬盘'}}
        var lang_use = 'zh_cn'
        if(typeof(lang) == 'string'){
            lang_use = lang
        }
        return dict[lang_use][key];
	}
};

