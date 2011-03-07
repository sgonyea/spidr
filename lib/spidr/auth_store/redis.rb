require 'redis'

module Spidr
  #
  # Stores {AuthCredential} objects organized by a website's scheme,
  # host-name and sub-directory.
  #
  module AuthStore
    class RedisAuthStore
      #
      # Creates a new auth store.
      #
      # @since 0.2.2
      #
      def initialize(host="localhost", port=6379, namespace="spidr")
        @redis  = Redis.new(:host => host, :port => port)
        @nspace = "#{namespace}::"
      end

      # 
      # Given a URL, return the most specific matching auth credential.
      #
      # @param [URI] url
      #   A fully qualified url including optional path.
      #
      # @return [AuthCredential, nil]
      #   Closest matching {AuthCredential} values for the URL,
      #   or `nil` if nothing matches.
      #
      # @since 0.2.2
      #
      def [](url)
        # normalize the url
        url   = URI(url.to_s) unless url.kind_of?(URI)
        r_key = @nspace + url.host_url

        return nil unless @redis.zcard r_key > 0

        path  = URI.expand_path(url.path)
        arity = path.split('/')
        keys  = @redis.zrevrangebyscore r_key, arity.length, 0, :withscores => true

        keys.each_slice(2) do |score, key|
          if arity[0,score].join('/') == key
            auth_loc = @nspace + key

            return  AuthCredential.new(@redis.hget(auth_loc, 'username'), @redis.hget(auth_loc, 'password'))
          end
        end

        return nil
      end

      # 
      # Add an auth credential to the store for supplied base URL.
      #
      # @param [URI] url_base
      #   A URL pattern to associate with a set of auth credentials.
      #
      # @param [AuthCredential]
      #   The auth credential for this URL pattern.
      #
      # @return [AuthCredential]
      #   The newly added auth credential.
      #
      # @since 0.2.2
      #
      def []=(url,auth)
        # normalize the url
        url   = URI(url.to_s) unless url.kind_of?(URI)
        r_key = @nspace + url.host_url
        path  = URI.expand_path(url.path)
        arity = path.split('/').length

        # normalize the URL path
        @redis.zadd r_key, arity, path
        @redis.hmset(r_key << path, auth.to_hash)

        return auth
      end

      #
      # Convenience method to add username and password credentials
      # for a named URL.
      #
      # @param [URI] url
      #   The base URL that requires authorization.
      #
      # @param [String] username
      #   The username required to access the URL.
      #
      # @param [String] password
      #   The password required to access the URL.
      #
      # @return [AuthCredential]
      #   The newly added auth credential.
      #
      # @since 0.2.2
      #
      def add(url,username,password)
        self[url] = AuthCredential.new(username,password)
      end

      #
      # Returns the base64 encoded authorization string for the URL
      # or `nil` if no authorization exists.
      #
      # @param [URI] url
      #   The url.
      #
      # @return [String, nil]
      #   The base64 encoded authorizatio string or `nil`.
      #
      # @since 0.2.2
      #
      def for_url(url)
        if (auth = self[url])
          return Base64.encode64("#{auth.username}:#{auth.password}")
        end
      end

      # 
      # Clear the contents of the auth store.
      #
      # @return [AuthStore]
      #   The cleared auth store.
      #
      # @since 0.2.2
      #
      def clear!
        # Do we want to make this so trivial? 
        # @credentials.clear
        # return self
      end

      #
      # Size of the current auth store (number of URL paths stored).
      #
      # @return [Integer]
      #   The size of the auth store.
      #
      # @since 0.2.2
      #
      def size
        self.keys.length
      end

      def keys
        @redis.keys(@nspace)
      end

      #
      # Inspects the auth store.
      #
      # @return [String]
      #   The inspected version of the auth store.
      #
      def inspect
        "#<#{self.class}: #{self.keys.inspect}>"
      end

    end
  end
end
