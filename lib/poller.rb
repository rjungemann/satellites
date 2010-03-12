module Satellites
  class Poller
    def initialize freq, &block
      @freq, @log, @block = freq, "", block
      @worker = Spork.spork(:log => @log) do
        loop do; @block.call; sleep @freq end
      end
    end
  end
end