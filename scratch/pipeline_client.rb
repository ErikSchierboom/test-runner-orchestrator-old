require 'ffi-rzmq'
require 'json'
require 'yaml'
require 'securerandom'

class PipelineClient

  attr_reader :address, :context, :socket

  def initialize(address="tcp://localhost:5555")
    @address = address
    @context = ZMQ::Context.new(1)
    open_socket
    at_exit do
      close_socket
    end
  end

  def test_run(track_slug, exercise_slug, solution_slug, iteration_folder)
    params = {
      action: "test_solution",
      track_slug: track_slug,
      container_version: "b6ea39ccb2dd04e0b047b25c691b17d6e6b44cfb",
      exercise_slug: exercise_slug,
      solution_slug: solution_slug,
      iteration_folder: iteration_folder
    }
    puts "MSG: #{params}"
    msg = params.to_json
    send_msg(msg, 10000)
  end

  private

  def open_socket
    @socket = context.socket(ZMQ::REQ)
    @socket.setsockopt(ZMQ::LINGER, 0)
    @socket.connect(address)
  end

  def close_socket
    @socket.close
  end

  def send_msg(msg, timeout)
    socket.setsockopt(ZMQ::RCVTIMEO, timeout*1000)
    send_result = socket.send_string(msg)
    response = ""
    recv_result = socket.recv_string(response)
    puts recv_result
    puts response
    raise("RCV timeout") if recv_result < 0
    parsed = JSON.parse(response)
    return parsed
  end

end
