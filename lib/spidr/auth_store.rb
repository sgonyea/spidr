require 'base64'

module Spidr
  #
  # Stores {AuthCredential} objects organized by a website's scheme,
  # host-name and sub-directory.
  #
  module AuthStore
    autoload :MemoryAuthStore,  'spidr/auth_store/memory'
    autoload :RedisAuthStore,   'spidr/auth_store/redis'
  end

  # add a def self.new(opts={}) where passing :redis => ... gives you a Redis Auth Store?
end
