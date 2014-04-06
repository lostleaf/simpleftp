require 'socket'
require 'thread'
require './cmdhandler'

module SimpleFtp
    Conn = Struct.new(:client) do
        CRLF = "\r\n"

        def gets
            client.gets CRLF
        end

        def respond(msg)
            client.write msg
            client.write CRLF
        end

        def close
            client.close
        end
    end

    class Server
        def initialize port=21
            @ctrl_socket = TCPServer.new(port)
            trap(:INT) {exit}
        end

        def run
            Thread.abort_on_exception = true
            loop do 
                conn = Conn.new(@ctrl_socket.accept)

                Thread.new do 
                    conn.respond "220 Simple Ftp Server by lostleaf"

                    handler = SimpleFtp::CMDHandler.new(conn)

                    loop do 
                        request = conn.gets

                        if request
                            result = handler.handle(request)
                            conn.respond result
                            puts request
                            puts result
                            puts
                        else
                            conn.close
                            break
                        end
                    end
                end
            end
        end

    end
end

server = SimpleFtp::Server.new(12345)
server.run
