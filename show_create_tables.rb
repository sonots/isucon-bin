#!/usr/bin/env ruby

# export ISU4_DB_HOST=localhost
# export ISU4_DB_PORT=3306
# export ISU4_DB_USER=isucon
# export ISU4_DB_PASSWORD=isucon
# export ISU4_DB_NAME=isu4_qualifier

def db_user
  ENV['DB_USER'] || ENV['ISU5_DB_USER'] || ENV['ISU4_DB_USER']
end

def db_password
  ENV['DB_PASSWORD'] || ENV['ISU5_DB_PASSWORD'] || ENV['ISU4_DB_PASSWORD']
end

def db_host
  ENV['DB_HOST'] || ENV['ISU5_DB_HOST'] || ENV['ISU4_DB_HOST']
end

def db_name
  ENV['DB_NAME'] || ENV['ISU5_DB_NAME'] || ENV['ISU4_DB_NAME']
end

def mysql
  "mysql -u#{db_user} -p#{db_password} -h #{db_host} #{db_name}"
end

tables = `#{mysql} -B -N -e 'show tables' | egrep -v 'schema_migrations|repli_chk|repli_clock'`.split("\n")
tables.each do |table|
  cmd = "show create table #{table}"
  $stdout.puts "> #{cmd}"
  $stdout.puts `#{mysql} -B -N -e '#{cmd}'`.split("\t")[1].split("\\n").join("\n")
end
tables.each do |table|
  cmd = "select count(1) from #{table}"
  $stdout.puts "> #{cmd}"
  $stdout.puts `#{mysql} -B -N -e '#{cmd}'`
end
