#!/usr/bin/env ruby
# ruby show_create_tables.rb -u USER -p PASSWORD -h HOST -P port DB > ~/log/show_create_tables.txt

require 'optparse'

class ShowCreateTable
  class CLI
    def parse_options(argv = ARGV)
      op = OptionParser.new

      self.class.module_eval do
        define_method(:usage) do |msg = nil|
          puts op.to_s
          puts "error: #{msg}" if msg
          exit 1
        end
      end

      opts = {
        user: 'root',
        password: '',
        host: 'localhost',
        port: '3306',
      }

      op.on('-u', '--user VALUE', "username (default: #{opts[:user]})") {|v|
        opts[:user] = v
      }
      op.on('-p', '--password VALUE', "password (default: #{opts[:password]})") {|v|
        opts[:password] = v
      }
      op.on('-h', '--host VALUE', "host (default: #{opts[:host]})") {|v|
        opts[:host] = v
      }
      op.on('-P', '--port VALUE', "port (default: #{opts[:port]})") {|v|
        opts[:port] = v
      }

      op.banner += ' DB'
      begin
        args = op.parse(argv)
      rescue OptionParser::InvalidOption => e
        usage e.message
      end

      if args.size < 1
        usage 'number of arguments is less than 1'
      end

      @user = opts[:user]
      @password = opts[:password]
      @db = args[0]
      @host = opts[:host]
      @port = opts[:port]
    end

    def run
      parse_options

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
      puts "$ sudo ls -lh /var/lib/mysql/#{@db}"
      puts `sudo ls -lh /var/lib/mysql/#{@db}`
    end

    private

    def mysql
      "mysql -u#{@user}#{@password.empty? ? "" : " -p#{@password}"} -h #{@host} -P #{@port} #{@db}"
    end
  end
end

ShowCreateTable::CLI.new.run
