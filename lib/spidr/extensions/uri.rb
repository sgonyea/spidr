require 'uri'

module URI
  #
  # Expands a URI decoded path, into a proper absolute path.
  #
  # @param [String] path
  #   The path from a URI.
  #
  # @return [String]
  #   The expanded path.
  #
  # @example
  #   URI.expand_path('./path')
  #   # => "path"
  #
  # @example
  #   URI.expand_path('test/../path')
  #   # => "path"
  #
  # @example
  #   URI.exand_path('/test/path/')
  #   # => "/test/path/"
  #
  # @example
  #   URI.expand_path('/test/../path')
  #   # => "/path"
  #
  def URI.expand_path(path)
    dirs = path.gsub(/[\/]{2,}/,'/').scan(/[^\/]*\/|[^\/]+$/)
    new_dirs = []

    dirs.each do |dir|
      if (dir == '..' || dir == '../')
        new_dirs.pop
      elsif (dir != '.' && dir != './')
        new_dirs.push(dir)
      end
    end

    unless new_dirs.empty?
      new_dirs.join
    else
      '/'
    end
  end

  class Generic
    def host_url
      @host_url ||= "#{self.scheme}://#{self.host}#{self.port ? ":#{self.port}" : ''}"
    end
  end
end
