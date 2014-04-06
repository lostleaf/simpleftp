module SimpleFtp
    class CMDHandler
        CRLF = "\r\n"

        def initialize conn 
            @conn = conn
            @pwd  = ['/']
            Dir.mkdir "root" unless Dir.exist? "root"
            @abs_root = File.join(Dir.pwd, "root")
            @from_name = nil
        end

        def usr_pwd
            File.join @pwd
        end

        def abs_path name
            File.join [@abs_root, *@pwd, name]
        end

        def handle_cwd name
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

        def handle_pwd option
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
            begin
                file_path = abs_path(name)
                return "550 RETR failed. File not found." unless File.exist? file_path
                return "550 RETR failed. Cannot read a directory." if File.directory? file_path

                file = File.open(abs_path(name), 'r')
                @conn.respond "125 Data transfer starting #{file.size} bytes"

                size_bytes = IO.copy_stream(file, @data_socket)

                return "226 Closing data connection, sent #{size_bytes} bytes"
            ensure
                @data_socket.close
            end
        end

        def handle_list option
            @conn.respond "125 Opening data connection for file list"

            result = Dir.entries(abs_path('')).join(CRLF)
            @data_socket.write(result)
            @data_socket.close

            "226 Closing data connection, sent #{result.size} bytes"
        end

        def handle_quit option
            "221 Goodbye"
        end
        
        def handle_user option
            "230 Logged in anonymously"
        end

        def handle_syst option
            "215 UNIX Simple FTP"
        end

        def handle_dele name
            file_path = abs_path(name)
            begin
                File.delete file_path
            rescue => err
                puts err
                return "550 DELE failed."
            end

            "250 DELE successful"
        end

        def handle_mdtm name
            file_path = abs_path name
            return "550 no such file" unless File.exist? file_path
            return "213 #{File.mtime(file_path).to_s}"
        end

        def handle_mkd name
            file_path = abs_path name
            begin
                Dir.mkdir file_path
            rescue => err
                return "550 #{err.to_s}"
            end

            "257 \"#{File.join usr_pwd, name}\" created successfully"
        end

        def handle_rmd name
            file_path = abs_path name
            begin
                Dir.rmdir file_path
            rescue => err
                return "550 #{err.to_s}"
            end

            "250 Directory deleted successfully"
        end

        def handle_size name
            file_path = abs_path name
            begin
                size = File.size file_path
                return "213 #{size}"
            rescue => err
                return "550 #{err.to_s}"
            end
        end

        def handle_stor name
            begin
                file_path = abs_path(name)
                return "550 RETR failed. File already exists." if File.exist? file_path

                file = File.open(abs_path(name), 'w')
                @conn.respond "125 Data transfer starting"

                size_bytes = IO.copy_stream(@data_socket, file)

                return "226 Closing data connection, sent #{size_bytes} bytes"
            rescue => err
                return "451 #{err.to_s}"
            ensure
                @data_socket.close
            end
        end

        def handle_rnfr name
            file_path = abs_path name
            if File.exists? name 
                @from_name = name
                "350 File exists"
            else
                "550 File not Found"
            end
        end

        def handle_rnto name
            file_path = abs_path name
            begin
                puts @from_name
                puts name
                File.rename abs_path(@from_name), file_path
            rescue => err
                "550 #{err.to_s}"
            end

            "250 Rename successfully"
        end

        def handle(data)
            cmd, option = data.strip.split(/\s+/, 2)
            method_name = "handle_#{cmd.downcase}"
            if respond_to? method_name
                send method_name, option
            else
                "502 Don't know how to respond to #{cmd}"
            end
        end
    end
end
