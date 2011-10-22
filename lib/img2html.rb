require "img2html/encoder"

module Img2Html
  class << self
    def encode(path)
      Encoder.new(path).encode
    end
  end
end
