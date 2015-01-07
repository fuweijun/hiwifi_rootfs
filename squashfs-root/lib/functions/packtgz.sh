. /lib/functions/healib.sh

pack_tgz()
{
	local trigger_type="$1"
	local trigger_path=$INFOGATHER_BASE_PATH/$trigger_type
	local files=""
	local file=""

	[ -d $trigger_path/db ] || return 1

	mkdir -p $trigger_path/tgz

	files=$(ls $trigger_path/db)
	for file in $files
	do
		tar -czf $trigger_path/tgz/$file.tgz -C $trigger_path/db $file 2> /dev/null
	done

	return 0
}
