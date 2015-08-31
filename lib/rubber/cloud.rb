require "rubber/cloud/base"

module Rubber
  module Cloud

    def self.get_provider(provider, env = nil, capistrano = nil, cloud_provider_env = nil)
      require "rubber/cloud/#{provider}"
      clazz = Rubber::Cloud.const_get(Rubber::Util.camelcase(provider))
      if cloud_provider_env.blank?
      	@provider_env = env.cloud_providers[provider]
      else
      	@provider_env = cloud_provider_env
      end
      return clazz.new(@provider_env, capistrano)
    end

  end
end
