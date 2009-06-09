require 'iconv'
puts Iconv.conv('ascii//ignore//translit', 'utf-8', 'ávecéspñaúà')