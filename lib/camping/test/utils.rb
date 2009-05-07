# Camping::TestUtils contains various classes and modules needed by camping/test
module Camping::TestUtils
  ASSIGNS = "camping.assigns"
  COOKIES = "camping.cookies"
  STATE   = "camping.state"
  Server  = Camping::Server
  
  # Used for mocking file-uploads. You will probably use it through
  # the Tests::Web#upload helper.
  class MockUpload
    attr_accessor :filename, :content
    RAND = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    
    # Creates a new file-upload called +filename+. See examples below for
    # availble options:
    #   
    #   MockUpload.new('image.jpg')                      # Contains 100 random chars
    #   MockUpload.new('image.jpg', :length => 1000)     # Contains 1000 random chars
    #   MockUpload.new('image.jpg', :content => "Other") # Contains "Other" 
    def initialize(filename, opts = {})
      @filename = filename
      @content = opts[:content] || random_content(opts[:length] || 100)
    end
    
  private
    
    # Generates random content
    def random_content(length)
      (1..length).map { RAND[rand(RAND.length)] }.join ''
    end
  end
  
  class FormBuilder
    def initialize(method, input = nil)
      @method = method
      @input = input
    end

    def query?
      @method == "GET" && @input.kind_of?(Hash)
    end

    def form?
      @method != "GET"
    end

    def raw?
      form? && @input.kind_of?(String)
    end

    def urlencoded?
      form? && @input.kind_of?(Hash)
    end

    def multipart?
      urlencoded? && @input.any? { |k, v| v.is_a?(MockUpload) }
    end

    def build
      opts = {}
      case
      when raw?  
        opts['CONTENT_TYPE'] = 'application/x-www-form-urlencoded'
        opts[:input] = @input
      when query?
        opts[:query] = build_query(@input)
      when multipart?
        boundary = "-----TeStAbLeCaMpInGiStEsTaBlE"
        opts['CONTENT_TYPE'] = "multipart/form-data; boundary=#{boundary}"
        opts[:input] = build_multipart(@input, boundary)
      when urlencoded?
        opts['CONTENT_TYPE'] = 'application/x-www-form-urlencoded'
        opts[:input] = build_query(@input)
      end
      opts['CONTENT_LENGTH'] = opts[:input].length if opts[:input]
      opts
    end

    def build_multipart(params, boundary)
      params.map do |(key, value)|
        key = esc(key)
        s = if value.is_a?(MockUpload)
          build_file_segment(key, value)
        else
          build_segment(key, value)
        end
        "--#{boundary}\r\n#{s}"
      end.join + "--#{boundary}--"
    end

    def build_query(params)
      Rack::Utils.build_query(params)
    end
    
    def esc(s)
      Rack::Utils.escape(s)
    end

    def build_file_segment(key, upload)
      filename = esc(upload.filename)
      content = upload.content
      "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{filename}\"\r\nContent-Transfer-Encoding: binary\r\n\r\n" + content + "\r\n"
    end

    def build_segment(key, value)
      "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n#{value}\r\n"
    end
  end 
end