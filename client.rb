require 'socket'
require 'thread'
require 'thwait'
module SimpleFtp
    class Handler
        CRLF = "\r\n"
        PORT_STR = "PORT 127,0,0,1,48,58"

        def initialize socket
            @socket = socket
            puts @socket.gets
            @data_server = TCPServer.new(12346)
        end
        
        def handle_pwd options
            send_recv "PWD"
        end

        def handle_cd options
            send_recv "CWD #{options}"
        end

        def handle_user options
            send_recv "USER"
        end

        def handle_mkdir options
            send_recv "MKD #{options}"
        end

        def handle_rmdir options
            send_recv "RMD #{options}"
        end

        def handle_rm options 
            send_recv "DELE #{options}"
        end

        def handle_mv options
            from, to = options.split(/\s+/, 2)
            unless send_recv("RNFR #{from}").start_with?("5")
                send_recv "RNTO #{to}"
            end
        end

        def handle_ls options
            puts send_recv PORT_STR
            conn = @data_server.accept
            puts send_recv "LIST"
            puts conn.read
            conn.close
            @socket.gets
        end

        def handle_get options
            puts send_recv PORT_STR
            conn = @data_server.accept
            puts send_recv "RETR #{options}"
            file = File.open(options, 'w')
            IO.copy_stream(conn, file)
            conn.close
            @socket.gets
        end

        def handle_put options
            puts send_recv PORT_STR
            conn = @data_server.accept
            puts send_recv "STOR #{options}"
            file = File.open(options, 'r')
            IO.copy_stream(file, conn)
            conn.close
            @socket.gets
        end

        def handle_bye options
            puts send_recv "QUIT"
            exit(0)
        end

        def send_recv msg
            @socket.write msg + CRLF
            recv_msg = @socket.gets
        end

        def handle cmd, options
            method_name = "handle_#{cmd}"
            if respond_to? method_name
                send method_name, options
            else
                "Undefined command #{cmd}"
            end
        end
    end

    class Client
        CRLF = "\r\n"
    
        def initialize ip, port = 21
            @handler = Handler.new(TCPSocket.new(ip, port))
        end

        def run
            loop do
                print "> "
                cmd, options = gets.strip.split(/\s+/, 2)
                puts @handler.handle cmd, options
            end
        end
    end
end

client = SimpleFtp::Client.new('127.0.0.1', 12345)
client.run
