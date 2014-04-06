module SimpleFtp
    class CMDHandler
        CRLF = "\r\n"

        def initialize conn 
            @conn = conn
            @pwd  = ['/']
            Dir.mkdir "root" unless Dir.exist? "root"
            @abs_root = File.join(Dir.pwd, "root")
        end

        def usr_pwd
            File.join @pwd
        end

        def abs_path name
            File.join [@abs_root, *@pwd, name]
        end

        def handle_cwd(name)
            path = abs_path(name)
            if File.directory? path
                if name == '..'
                    @pwd = @pwd[0..-2] if @pwd.length > 1
                else
                    @pwd << name unless name == '.'
                end
                "250 CWD successful. \"#{usr_pwd}\" is current directory"
            else
                "550 CWD failed. directory not found"
            end
        end

        def handle_pwd
            "257 \"#{usr_pwd}\" is the current directory"
        end

        def handle_port option
            opts = option.strip.split(',')
            ip   = opts[0..3].join('.')
            port = opts[4].to_i * 256 + opts[5].to_i
            
            @data_socket = TCPSocket.new(ip, port)
            "200 Active connection established (#{port})"
        end

        def handle_retr name
            file = File.open(abs_path(name), 'r')
            @conn.respond "125 Data transfer starting #{file.size} bytes"

            bytes = IO.copy_stream(file, @data_socket)
            @data_socket.close

            "226 Closing data connection, sent #{data.length} bytes"
        end

        def handle_list
            @conn.respond "125 Opening data connection for file list"

            result = Dir.entries(abs_path('')).join(CRLF)
            @data_socket.write(result)
            @data_socket.close

            "226 Closing data connection, sent #{result.size} bytes"
        end

        def handle_quit
            "221 Goodbye"
        end
        
        def handle_user
            "230 Logged in anonymously"
        end

        def handle_syst
            "215 UNIX Simple FTP"
        end

        def handle(data)
            cmd, option = data.strip.split(/\s+/, 2)
            case cmd.upcase
            when 'USER'
                handle_user 
            when 'SYST'
                handle_syst
            when 'CWD'
                handle_cwd option
            when 'PWD'
                handle_pwd
            when 'PORT'
                handle_port option
            when 'RETR'
                handle_retr option
            when 'LIST'
                handle_list
            when 'QUIT'
                handle_quit
            else
                # puts data
                "502 Don't know how to respond to #{cmd}"
            end
        end
    end
end
